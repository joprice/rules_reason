load(
    "//reason/private:extensions.bzl",
    "CMXA_EXT",
    "CMI_EXT",
    "CMO_EXT",
    "CMX_EXT",
    "C_EXT",
    "H_EXT",
    "MLI_EXT",
    "ML_EXT",
    "O_EXT",
)

load(
    "//reason/private:providers.bzl",
    "MlCompiledModule",
)

load(
    ":utils.bzl",
    "TARGET_BYTECODE",
    "TARGET_NATIVE",
    "select_compiler",
)

load("@bazel_skylib//lib:sets.bzl", "sets")

def ocaml_compile_library(
        ctx,
        ocamlc_flags,
        ocamlopt_flags,
        c_sources,
        ml_sources,
        outputs,
        runfiles,
        sorted_sources,
        sorted_cmo,
        sorted_cmx,
        toolchain,
        deps,
):
    """
    Compile a given set of OCaml .ml and .mli sources to their .cmo, .cmi, and
    .cmx counterparts.
  """

    source_dirs = sets.make()
    for source in ml_sources:
      sets.insert(source_dirs, source.dirname)

    move_sources = """\
      find {source_dir} \
          \( -name "*.cm*" -or -name "*.o" \) \
          -exec cp {{}} {output_dir}/ \;
    """.format(
        source_dir=" ".join(sets.to_list(source_dirs)),
        output_dir=outputs[0].dirname,
    ) if not ctx.attr.wrapped else """\
      for file in $(find {source_dir} \
          \( -name "*.cm*" -or -name "*.o" \)); do
          dir=$(dirname $file)
          base=$(basename $file)
          no_ext="${{base%.*}}"
          updated=""
          if [[ $no_ext != {name} ]]; then
            updated="{name}__$(tr '[:lower:]' '[:upper:]' <<< ${{base:0:1}})${{base:1}}"
          fi
          echo $base
          cp $file {output_dir}/$updated
      done
    """.format(
        name=ctx.attr.name,
        source_dir=" ".join(sets.to_list(source_dirs)),
        output_dir=outputs[0].dirname,
    )

    collect_sources = "" if ctx.attr.pack else """\
      {move_sources}
      for line in $(cat {ml_sources}); do
        if [[ "$line" != *{name}__.ml ]]; then
          cp -f $line {output_dir}/
        fi
      done
    """.format(
        name=ctx.attr.name,
        output_dir=outputs[0].dirname,
        source_dir=" ".join(sets.to_list(source_dirs)),
        ml_sources=sorted_sources.path,
        move_sources=move_sources,
    )

    cmo = []
    #cmo = [file.path for file in deps if file.basename.endswith(CMO_EXT)] if ctx.attr.pack else []
    packed_modules = []
    cmi = []
    if ctx.attr.pack:
      for file in deps:
        if file.basename.endswith(CMI_EXT):
          no_ext = file.basename[len(file.extension):]
          if no_ext in packed_modules:
            cmi.append(file.path)
    #cmx = [file.path for file in deps if file.basename.endswith(CMX_EXT)] if ctx.attr.pack else []
    cmx = []

    ctx.actions.run_shell(
        inputs=runfiles,
        outputs=outputs,
        tools=[
            toolchain.ocamlc,
            toolchain.ocamlopt,
        ],
        command="""\
        # need to fail early, otherwise duplicate type errors will be shown
        #!/bin/bash
        set -eux

        #echo `pwd`

        # Compile .cmi and .cmo files
        {_ocamlc} {ocamlc_flags} $(cat {ml_sources}) $(cat {sorted_cmo}) {cmi}

        # Compile .cmx files
        {_ocamlopt} {ocamlopt_flags} $(cat {ml_sources}) {c_sources} {cmi} $(cat {sorted_cmx})


        mkdir -p {output_dir}

        # C sources will be compiled and put at the top level
        find . -maxdepth 1 \
            -name "*.o" \
            -exec cp {{}} {output_dir}/ \;

        {collect_sources}
        """.format(
            _ocamlc=toolchain.ocamlc.path,
            _ocamlopt=toolchain.ocamlopt.path,
            ocamlc_flags=" ".join(ocamlc_flags),
            ocamlopt_flags=" ".join(ocamlopt_flags),
            c_sources=" ".join([c.path for c in c_sources]),
            ml_sources=sorted_sources.path,
            sorted_cmo=sorted_cmo.path if sorted_cmo != None else "",
            sorted_cmx=sorted_cmx.path if sorted_cmx != None else "",
            output_dir=outputs[0].dirname,
            collect_sources=collect_sources,
            cmo=" ".join(cmo),
            cmi=" ".join(cmi),
            cmx=" ".join(cmx),
            #source_dir=" ".join(sets.to_list(source_dirs)),
        ),
        mnemonic="OCamlCompileLib",
        progress_message="Compiling ({_in}) to ({out})".format(
            _in=", ".join([s.basename for s in ml_sources] +
                          [c.basename for c in c_sources]),
            out=", ".join([s.basename for s in outputs]),
        ),
    )


def ocaml_compile_binary(
        ctx,
        arguments,
        base_libs,
        binfile,
        c_deps,
        c_sources,
        deps,
        ml_sources,
        runfiles,
        sorted_sources,
        target,
        toolchain,
):
    """
    Compile a given set of OCaml .ml and .mli sources to a single binary file

    Args:
      ctx: the context argument from the rule invoking this macro

      arguments: a list of string representing the compiler flags

      base_libs: a list of target objects from the OCaml stdlib to link against

      binfile: the binary file target

      c_deps: a list of transitive C dependency targets

      c_sources: depset of C sources for this binary

      deps: a list of transitive ML dependency targets

      ml_sources: a depset of ML sources for this binary

      runfiles: list of all the files that need to be present at runtime

      sorted_sources: a file target with ML sources in topological order

      target: whether to compile to a native or bytecode binary

      toolchain: the OCaml toolchain
    """

    compiler = select_compiler(toolchain, target)

    # Native binaries expect .cmx files while bytecode binaries expect .cmo
    expected_object_ext = CMX_EXT
    if target == TARGET_BYTECODE:
        expected_object_ext = CMO_EXT

    extra = []
    dep_libs = []
    for d in deps:
        name = d.basename
        if name == "graph.cmx":
          extra.append(d)
        if ML_EXT in name or MLI_EXT in name:
            dep_libs.extend([d])

    # Extract all .cmxa baselib dependencies to include in linking
    stdlib_libs = []
    for baselib in base_libs.to_list():
        if CMXA_EXT in baselib.basename:
            stdlib_libs += [baselib]

    source_dirs = sets.make()
    for source in ml_sources:
      sets.insert(source_dirs, source.dirname)

    ctx.actions.run_shell(
        inputs=runfiles,
        outputs=[binfile],
        tools=[
            toolchain.ocamlc,
            toolchain.ocamlopt,
            toolchain.ocamldep,
        ],
        command="""\
            #/usr/bin/env bash
            set -eux
        # Run ocamldep on all of the ml and mli dependencies for this binary
        {_ocamldep} \
            -sort \
            $(echo {dep_libs} | tr " " "\n" | grep ".ml*") \
            > .depend.all

        # Extract only the compiled cmx files to use as input for the compiler
        cat .depend.all \
            | tr " " "\n" \
            | grep ".ml$" \
            | sed "s/\.ml.*$/{expected_object_ext}/g" \
            | xargs \
            > .depend.cmx

        {_compiler} {arguments} \
            {c_objs} \
            {base_libs} \
            {extra} $(cat .depend.cmx) $(cat {ml_sources}) {c_sources}

        mkdir -p {output_dir}

        find {source_dir} -name "{pattern}" -exec cp {{}} {output_dir}/ \;

        """.format(
            _compiler=compiler.path,
            _ocamldep=toolchain.ocamldep.path,
            arguments=" ".join(arguments),
            base_libs=" ".join([b.path for b in stdlib_libs]),
            c_objs=" ".join([o.path for o in c_deps]),
            c_sources=" ".join([c.path for c in c_sources]),
            expected_object_ext=expected_object_ext,
            dep_libs=" ".join([l.path for l in dep_libs]),
            ml_sources=sorted_sources.path,
            output_dir=binfile.dirname,
            pattern=binfile.basename,
            source_dir=" ".join(sets.to_list(source_dirs)),
            extra =" ".join([f.path for f in extra]),
        ),
        mnemonic="OCamlCompileBin",
        progress_message="Compiling ({_in}) to ({out})".format(
            _in=", ".join([s.basename for s in ml_sources] +
                          [c.basename for c in c_sources]),
            out=binfile.basename),
    )

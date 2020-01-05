load(
    "//reason/private:extensions.bzl",
    "CM_EXTS",
    "CMA_EXT",
    "CMX_EXT",
    "CMXA_EXT",
    "MLI_EXT",
    "ML_EXT",
    "CMO_EXT",
)

load(
    "//reason/private:providers.bzl",
    "MlCompiledModule",
    "CCompiledModule",
)

load(
    ":ocamldep.bzl",
    _ocamldep="ocamldep",
)

load(
    ":utils.bzl",
    _build_import_paths="build_import_paths",
    _declare_outputs="declare_outputs",
    _find_base_libs="find_base_libs",
    _gather_files="gather_files",
    _group_sources_by_language="group_sources_by_language",
    _stdlib="stdlib",
)

load(
    ":compile.bzl",
    _ocaml_compile_library="ocaml_compile_library",
)

def generate_wrapper(ctx, ml_sources, toolchain):
    module = ctx.actions.declare_file(ctx.attr.name + "__" + ML_EXT)

    ctx.actions.run_shell(
        inputs=ml_sources,
        tools=[toolchain.ocamldep],
        outputs=[module],
        command="""#/usr/bin/env bash
          set -eux
          for source in {sources}; do
            base=$(basename $source)
            no_ext="${{base%.*}}"
            name={name}
            upperName="$(tr '[:lower:]' '[:upper:]' <<< ${{name:0:1}})${{name:1}}"
            module="$(tr '[:lower:]' '[:upper:]' <<< ${{no_ext:0:1}})${{no_ext:1}}"
            echo "module $module = ${{upperName}}__$module\n" >> {out}
          done
        """.format(
            name=ctx.attr.name,
            sources=" ".join([s.path for s in ml_sources if s.path.endswith(ML_EXT)]),
            out=module.path,
        ),
        mnemonic="OCamlDep",
        progress_message="Generating wrapper ({_in})".format(
            _in=", ".join([s.basename for s in ml_sources]),),
    )
    return module

def _ocaml_module_impl(ctx):
    name = ctx.attr.name

    toolchain = ctx.attr.toolchain[platform_common.ToolchainInfo]

    # Get standard library files and path
    (stdlib, stdlib_path) = _stdlib(toolchain)
    base_libs = _find_base_libs(stdlib, ctx.attr.base_libs)

    # Get all sources needed for compilation
    (sources, imports, deps, c_deps, stdlib_deps) = _gather_files(ctx)

    # Split sources for sorting
    (ml_sources, c_sources) = _group_sources_by_language(sources)

    module = None
    if ctx.attr.wrapped:
      module = generate_wrapper(ctx, ml_sources, toolchain)
      ml_sources.append(module)

    # Run ocamldep on the ML sources to compile in right order
    sorted_sources = _ocamldep(ctx, name, ml_sources, toolchain)

    sorted_cmo = None
    sorted_cmx = None
    if ctx.attr.pack:
      cmo = [file for file in deps if file.basename.endswith(CMO_EXT)] if ctx.attr.pack else []
      if len(cmo) > 0:
        sorted_cmo = _ocamldep(ctx, name + "_cmo", cmo, toolchain)

      cmx = [file for file in deps if file.basename.endswith(ML_EXT)] if ctx.attr.pack else []
      if len(cmx) > 0:
        sorted_cmx = _ocamldep(ctx, name + "_cmx", cmx, toolchain, native=True)
    #cmi = [file.path for file in deps if file.basename.endswith(CMI_EXT)] if ctx.attr.pack else []
    #cmx = [file.path for file in deps if file.basename.endswith(CMX_EXT)] if ctx.attr.pack else []

    #if name == "ocamlgraph":
    #print("cmo", cmo)
    #print("cmx", cmx)
    #print(sources)
    #print("deps {}".format(deps))
    #print("imports {}".format(imports))

    # Declare outputs
    (ml_outputs, c_outputs, ocamlc_flags, ocamlopt_flags) = _declare_outputs(ctx, sources)

    outputs = ml_outputs + c_outputs


    # Build runfiles
    runfiles = []
    runfiles.extend([sorted_sources])
    if sorted_cmo != None:
      runfiles.append(sorted_cmo)
    if sorted_cmx != None:
      runfiles.append(sorted_cmx)
    if module != None:
      runfiles.append(module)
    runfiles.extend(sources)
    runfiles.extend(deps)
    runfiles.extend(stdlib)

    # Compute import paths
    import_paths = _build_import_paths(imports, stdlib_path)

    compile_flag = ["-pack"] if ctx.attr.pack else ["-c"]
    common_flags = [
        "-color",
        "always",
        "-no-alias-deps",
        "-keep-locs",
        "-short-paths",
    ] + import_paths + compile_flag

    ocamlc_flags.extend(ctx.attr.ocamlc_flags + common_flags)
    ocamlopt_flags.extend(ctx.attr.ocamlopt_flags + common_flags)

    _ocaml_compile_library(
        ctx=ctx,
        ocamlc_flags=ocamlc_flags,
        ocamlopt_flags=ocamlopt_flags,
        outputs=outputs,
        runfiles=runfiles,
        sorted_sources=sorted_sources,
        sorted_cmo=sorted_cmo,
        sorted_cmx=sorted_cmx,
        ml_sources=ml_sources,
        c_sources=c_sources,
        toolchain=toolchain,
        deps=deps
    )

    #print("this deps", deps)

    return [
        DefaultInfo(
            files=depset(outputs),
            runfiles=ctx.runfiles(files=runfiles),
        ),
        MlCompiledModule(
            name=ctx.attr.name,
            srcs=ml_sources,
            deps=[] if ctx.attr.pack else deps,
            base_libs=base_libs,
            outs=ml_outputs,
        ),
        CCompiledModule(
            name=ctx.attr.name,
            srcs=c_sources,
            outs=c_outputs,
        ),
    ]


ocaml_module = rule(
    attrs={
        "srcs": attr.label_list(
            allow_files=[ML_EXT, MLI_EXT],
            mandatory=True,
        ),
        "deps": attr.label_list(
            allow_files=False,
            default=[],
        ),
        "base_libs": attr.string_list(default=[]),
        "toolchain": attr.label(
            # TODO(@ostera): rename this target to managed-platform
            default="//reason/toolchain:bs-platform",
            providers=[platform_common.ToolchainInfo],
        ),
        "ocamlc_flags": attr.string_list(default=[]),
        "ocamlopt_flags": attr.string_list(default=[]),
        "pack": attr.string(),
        "includes": attr.string_list(default=[]),
        "wrapped": attr.bool(default=False),
    },
    implementation=_ocaml_module_impl,
)

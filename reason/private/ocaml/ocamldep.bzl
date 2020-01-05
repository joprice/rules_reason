def ocamldep(ctx, name, sources, toolchain, native=False):
    sorted_sources = ctx.actions.declare_file(name + "_sorted_sources")

    in_ext="\.ml"
    out_ext = "\.cmx" if native else "\.ml"

    ctx.actions.run_shell(
        inputs=sources,
        tools=[toolchain.ocamldep],
        outputs=[sorted_sources],
        command="""\
            #/usr/bin/env bash
            set -eux
          {ocamldep} -sort {sources} | sed 's/{in_ext}/{out_ext}/g' > {out}
          """.format(
            in_ext=in_ext,
            out_ext=out_ext,
            ocamldep=toolchain.ocamldep.path,
            sources=" ".join([s.path for s in sources]),
            out=sorted_sources.path,
        ),
        mnemonic="OCamlDep",
        progress_message="Sorting ({_in})".format(
            _in=", ".join([s.basename for s in sources]),),
    )
    return sorted_sources

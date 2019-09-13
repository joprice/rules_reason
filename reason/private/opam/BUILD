package(default_visibility = ["//:__subpackages__"])

exports_files(["ocamlrun.tpl", "opam_package.tpl"])

genrule(
    name = "extract_binaries",
    srcs = ["@ocaml//:srcs"],
    outs = [
        "ocaml_stdlib.tar",
        "ocamlc.opt",
        "ocamldep.opt",
        "ocamlopt.opt",
        "ocamlrun",
    ],
    cmd = """\
      #ocaml_root=$$(pwd)/$(@D)
      ocaml_root=$$(pwd)/external/ocaml/

      cp -f $$ocaml_root/bin/ocamlc.opt   $(@D)/ocamlc.opt;
      cp -f $$ocaml_root/bin/ocamldep.opt $(@D)/ocamldep.opt;
      cp -f $$ocaml_root/bin/ocamlopt.opt $(@D)/ocamlopt.opt;
      cp -f $$ocaml_root/bin/ocamlrun $(@D)/ocamlrun;

      # pack ml stdlib preserving paths
      cd $$ocaml_root
      gtar --create lib/ocaml/* \
          > ../../$(location ocaml_stdlib.tar);

      """,
)

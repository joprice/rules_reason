def _reason_toolchain_impl(ctx):
  return [
      platform_common.ToolchainInfo(
          stdlib = ctx.attr.stdlib,
          bsc = ctx.file.bsc,
          ocamlc = ctx.file.ocamlc,
          refmt = ctx.file.refmt,
          )
      ]

_reason_toolchain = rule(
    implementation = _reason_toolchain_impl,
    attrs = {
        "stdlib": attr.label(
            mandatory = True,
            allow_files = True,
            executable = False,
            ),
        "bsc": attr.label(
            mandatory = True,
            allow_single_file = True,
            executable = True,
            cfg = "target",
            ),
        "ocamlc": attr.label(
            mandatory = True,
            allow_single_file = True,
            executable = True,
            cfg = "target",
            ),
        "refmt": attr.label(
            mandatory = True,
            allow_single_file = True,
            executable = True,
            cfg = "target",
            ),
        },
    )

def reason_toolchain(name, stdlib, bsc, ocamlc, refmt, **kwargs):
  """The minimum ReasonML toolchain.

  Args:
    refmt: the standard ReasonML reformatting tool
    bsc: the BuckleScript compiler
    ocamlc: the Ocaml compiler
    stdlib: a filegroup with the standard library the compiler is using
  """

  impl_name = name + "-platform"

  _reason_toolchain(
      name = impl_name,
      stdlib = stdlib,
      bsc = bsc,
      ocamlc = ocamlc,
      refmt = refmt,
  )

  native.toolchain(
      name = name,
      toolchain_type = "@com_github_ostera_rules_reason//reason/toolchain:toolchain",
      toolchain = ":{name}".format(name = impl_name),
      **kwargs
  )

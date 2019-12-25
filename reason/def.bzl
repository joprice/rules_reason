# Repository rules
load(
    "@com_github_ostera_rules_reason//reason/toolchain:toolchains.bzl",
    _reason_register_toolchains="reason_register_toolchains",
)


# Dependency rules
load("@com_github_ostera_rules_reason//reason/private/opam:opam_package.bzl",
     "opam_package")

# Binary/Library target rules
load(
    "@com_github_ostera_rules_reason//reason/private:reason_module.bzl",
    _reason_module = "reason_module",
)


load(
    "@com_github_ostera_rules_reason//reason/private:bs_module.bzl",
    _bs_module = "bs_module",
)

load(
    "@com_github_ostera_rules_reason//reason/private/ocaml:ocaml_binary.bzl",
    _ocaml_native_binary = "ocaml_native_binary",
    _ocaml_bytecode_binary = "ocaml_bytecode_binary",
)

load(
    "@com_github_ostera_rules_reason//reason/private/ocaml:ocaml_module.bzl",
    _ocaml_module="ocaml_module",
)

reason_module = _reason_module
bs_module = _bs_module
ocaml_module = _ocaml_module
ocaml_native_binary = _ocaml_native_binary
ocaml_bytecode_binary = _ocaml_bytecode_binary
reason_register_toolchains=_reason_register_toolchains

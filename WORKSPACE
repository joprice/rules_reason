workspace(name = "com_github_ostera_rules_reason")

###
### Bazel Tools!
###

load(
    "@com_github_ostera_rules_reason//reason/repositories:bazel.bzl",
    "bazel_repositories",
)

bazel_repositories(
    bazel_version = "0.15.2",
    bazel_sha256 = "",
    rules_go_version = "436452edc29a2f1e0edc22d180fbb57c27e6d0af",
    rules_go_sha256 = "09669ffc724b21ab3ee8fd58c8b52b27dd216552add9098daf16e0f1d3654626",
    buildtools_version = "49a6c199e3fbf5d94534b2771868677d3f9c6de9",
    buildtools_sha256 = "edf39af5fc257521e4af4c40829fffe8fba6d0ebff9f4dd69a6f8f1223ae047b",
    )

load("@bazel_skylib//:workspace.bzl", "bazel_skylib_workspace")
bazel_skylib_workspace()

load(
    "@com_github_ostera_rules_reason//reason/repositories:tools.bzl",
    "setup_repo_tools",
)

setup_repo_tools()

###
### Nix Repositories
###

load(
    "@com_github_ostera_rules_reason//reason/repositories:nix.bzl",
    "nix_repositories",
)

nix_repositories(
    nix_sha256 = "c4ca88951f59e443b430f1532ae2a875c45643206590f7fa90c905a952b764bc",
    nix_version = "b83e0d09ab0819480ce3ec8d57d2673d6270c3c3",
)


load(
    "@io_tweag_rules_nixpkgs//nixpkgs:nixpkgs.bzl",
    "nixpkgs_git_repository",
    "nixpkgs_package",
)
#
nixpkgs_git_repository(
    name="reason-nixpkgs",
    revision="5a12a5bd5735b52e98f583d35ecb690902fa7c09",
    #sha256=nixpkgs_sha256,
)

###
### Register Reason Toolchain
###

load(
    "@com_github_ostera_rules_reason//reason:def.bzl",
    "reason_register_toolchains",
)

reason_register_toolchains(
    nix_repository="@reason-nixpkgs",
    bs_sha256 = "45d8a93a68976d01b62e373b9fda2d8b839bd6610e3d9820e146cab9882b4561",
    bs_version = "3904b20a4036370b40617019f716f6fef02ae0b6",
)

###
### Register Nexsted Workspaces
###

local_repository(
    name = "examples",
    path = "examples",
)

local_repository(
    name = "retool",
    path = "retool",
)

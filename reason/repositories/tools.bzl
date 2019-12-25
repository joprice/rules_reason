load("@io_bazel_rules_go//go:deps.bzl", "go_rules_dependencies",
     "go_register_toolchains")


def setup_repo_tools():
    go_rules_dependencies()
    go_register_toolchains()

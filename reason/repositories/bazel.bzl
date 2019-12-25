load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def bazel_repositories(
        bazel_version,
        bazel_sha256,
        rules_go_version,
        rules_go_sha256,
        buildtools_version,
        buildtools_sha256,
):
    #http_archive(
    #    name="io_bazel",
    #    sha256=bazel_sha256,
    #    strip_prefix="bazel-%s" %
    #    bazel_version,  # Should match current Bazel version
    #    urls=[
    #        "http://bazel-mirror.storage.googleapis.com/github.com/bazelbuild/bazel/archive/%s.tar.gz"
    #        % bazel_version,
    #        "https://github.com/bazelbuild/bazel/archive/%s.tar.gz" %
    #        bazel_version,
    #    ],
    #)

    http_archive(
      name = "io_bazel_rules_go",
      urls = [
          "https://storage.googleapis.com/bazel-mirror/github.com/bazelbuild/rules_go/releases/download/v0.20.3/rules_go-v0.20.3.tar.gz",
          "https://github.com/bazelbuild/rules_go/releases/download/v0.20.3/rules_go-v0.20.3.tar.gz",
      ],
      sha256 = "e88471aea3a3a4f19ec1310a55ba94772d087e9ce46e41ae38ecebe17935de7b",
    )

    http_archive(
        name = "bazel_skylib",
        urls = [
            "https://mirror.bazel.build/github.com/bazelbuild/bazel-skylib/releases/download/1.0.2/bazel-skylib-1.0.2.tar.gz",
            "https://github.com/bazelbuild/bazel-skylib/releases/download/1.0.2/bazel-skylib-1.0.2.tar.gz",
        ],
        sha256 = "97e70364e9249702246c0e9444bccdc4b847bed1eb03c5a3ece4f83dfe6abc44",
    )

    #http_archive(
    #    name="io_bazel_rules_go",
    #    sha256=rules_go_sha256,
    #    strip_prefix="rules_go-%s" % rules_go_version,  # branch master
    #    urls=[
    #        "https://github.com/bazelbuild/rules_go/archive/%s.zip" %
    #        rules_go_version
    #    ],
    #)

    #http_archive(
    #    name="com_github_bazelbuild_buildtools",
    #    sha256=buildtools_sha256,
    #    strip_prefix="buildtools-%s" % buildtools_version,  # branch master
    #    urls=[
    #        "https://github.com/bazelbuild/buildtools/archive/%s.zip" %
    #        buildtools_version
    #    ],
    #)

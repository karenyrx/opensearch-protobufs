workspace(name = "proto_workspace")

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

# Protocol Buffers dependencies
http_archive(
    name = "com_google_protobuf",
    sha256 = "d0f5f605d0d656007ce6c8b5a82df3037e1d8fe8b121ed42e536f569dec16113",
    strip_prefix = "protobuf-3.14.0",
    urls = ["https://github.com/protocolbuffers/protobuf/archive/v3.14.0.tar.gz"],
)

load("@com_google_protobuf//:protobuf_deps.bzl", "protobuf_deps")
protobuf_deps()

# Java rules
http_archive(
    name = "rules_java",
    sha256 = "220b87d8cfabd22d1c6d8e3cdb4249abd4c93dcc152e0667db061fb1b957ee68",
    urls = ["https://github.com/bazelbuild/rules_java/releases/download/0.1.1/rules_java-0.1.1.tar.gz"],
)

load("@rules_java//java:repositories.bzl", "rules_java_dependencies")
rules_java_dependencies()

# Proto rules
http_archive(
    name = "rules_proto",
    sha256 = "66bfdf8782796239d3875d37e7de19b1d94301e8972b3cbd2446b332429b4df1",
    strip_prefix = "rules_proto-4.0.0",
    urls = ["https://github.com/bazelbuild/rules_proto/archive/refs/tags/4.0.0.zip"],
)

load("@rules_proto//proto:repositories.bzl", "rules_proto_dependencies", "rules_proto_toolchains")
rules_proto_dependencies()
rules_proto_toolchains()

# We're not using Python or Go rules through Bazel anymore
# Instead, we're using the protoc command directly in our scripts

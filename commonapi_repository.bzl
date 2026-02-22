"""
Repository rule for CommonAPI code generation

This rule generates code from FIDL files using CommonAPI generators
and creates BUILD.bazel files automatically.
"""

def _commonapi_gen_repo_impl(ctx):
    """Implementation of commonapi_gen_repo repository rule"""
    
    interface_name = ctx.attr.interface_name
    
    # Watch all FIDL and FDEPL files for changes
    # This makes the repository invalidate when these files change
    for fidl_file in ctx.attr.fidl_files:
        ctx.watch(fidl_file)
    
    for fdepl_file in ctx.attr.fdepl_files:
        ctx.watch(fdepl_file)
    
    # Get paths to generator executables from attributes
    # These already point to the actual executable files
    core_gen_path = ctx.path(Label("@commonapi_core_generator//:commonapi-core-generator-linux-x86_64"))
    someip_gen_path = ctx.path(Label("@commonapi_someip_generator//:commonapi-someip-generator-linux-x86_64"))
    
    # Copy FIDL files to fidl directory
    ctx.execute(["mkdir", "-p", "fidl"])
    
    # Copy all FIDL files
    for fidl_file in ctx.attr.fidl_files:
        fidl_path = ctx.path(fidl_file)
        fidl_filename = str(fidl_path).split("/")[-1]
        ctx.execute(["cp", str(fidl_path), "fidl/{}".format(fidl_filename)])
    
    # Copy all FDEPL files
    for fdepl_file in ctx.attr.fdepl_files:
        fdepl_path = ctx.path(fdepl_file)
        fdepl_filename = str(fdepl_path).split("/")[-1]
        ctx.execute(["cp", str(fdepl_path), "fidl/{}".format(fdepl_filename)])
    
    # Create output directories
    ctx.execute(["mkdir", "-p", "generated_core"])
    ctx.execute(["mkdir", "-p", "generated_someip"])
    ctx.execute(["mkdir", "-p", "eclipse_config_core"])
    ctx.execute(["mkdir", "-p", "eclipse_config_someip"])

    # Run CommonAPI core generator with main FIDL file
    core_result = ctx.execute([
        str(core_gen_path),
        "-data", "eclipse_config_core",
        "-configuration", "eclipse_config_core",
        "-d", "generated_core",
        "-sk",
        "./fidl/{}.fidl".format(interface_name),
    ])
    
    if core_result.return_code != 0:
        fail("CommonAPI core generator failed:\n" + core_result.stderr)
    
    # Run CommonAPI SOME/IP generator with main FDEPL file
    someip_result = ctx.execute([
        str(someip_gen_path),
        "-data", "eclipse_config_someip",
        "-configuration", "eclipse_config_someip",
        "-d", "generated_someip",
        "-sp", "fidl",
        "fidl/{}.fdepl".format(interface_name),
    ])
    
    if someip_result.return_code != 0:
        fail("CommonAPI SOME/IP generator failed:\n" + someip_result.stderr)
    
    # Create BUILD.bazel for core generated code
    core_build = """
load("@rules_cc//cc:defs.bzl", "cc_library")

cc_library(
    name = "core",
    hdrs = [
        "generated_core/v0/commonapi/examples/{interface_name}.hpp",
        "generated_core/v0/commonapi/examples/{interface_name}Proxy.hpp",
        "generated_core/v0/commonapi/examples/{interface_name}ProxyBase.hpp",
        "generated_core/v0/commonapi/examples/{interface_name}Stub.hpp",
        "generated_core/v0/commonapi/examples/{interface_name}StubDefault.hpp",
    ],
    includes = ["generated_core"],
    visibility = ["//visibility:public"],
    deps = ["@capicxx_core_runtime//:common_core_api_interface"],
)
""".format(interface_name=interface_name)
    
    ctx.file("BUILD.bazel", core_build)
    
    # Create BUILD.bazel for someip generated code
    someip_build = """
load("@rules_cc//cc:defs.bzl", "cc_shared_library", "cc_library")

cc_library(
    name = "someip",
    srcs = [
        "generated_someip/v0/commonapi/examples/{interface_name}SomeIPDeployment.cpp",
        "generated_someip/v0/commonapi/examples/{interface_name}SomeIPProxy.cpp",
        "generated_someip/v0/commonapi/examples/{interface_name}SomeIPStubAdapter.cpp",
    ],
    hdrs = [
        "generated_someip/v0/commonapi/examples/{interface_name}SomeIPDeployment.hpp",
        "generated_someip/v0/commonapi/examples/{interface_name}SomeIPProxy.hpp",
        "generated_someip/v0/commonapi/examples/{interface_name}SomeIPStubAdapter.hpp",
        "generated_someip/v0/commonapi/examples/{interface_name}SomeIPCatalog.json",
    ],
    includes = ["generated_someip"],
    visibility = ["//visibility:public"],
    deps = [
        ":core",
        "@capicxx_someip_runtime//:capicxx_someip_runtime_interface",
    ],
)

cc_shared_library(
    name = "{interface_name}-someip",
    deps = [":someip"],
    visibility = ["//visibility:public"],
)
""".format(interface_name=interface_name)
    
    ctx.file("BUILD.bazel", core_build + "\n\n" + someip_build)

commonapi_gen_repo = repository_rule(
    implementation = _commonapi_gen_repo_impl,
    attrs = {
        "interface_name": attr.string(
            mandatory = True,
            doc = "Name of the CommonAPI interface (e.g., 'HelloWorld')",
        ),
        "core_generator": attr.label(
            allow_single_file = True,
            mandatory = True,
            doc = "CommonAPI core generator executable",
        ),
        "someip_generator": attr.label(
            allow_single_file = True,
            mandatory = True,
            doc = "CommonAPI SOME/IP generator executable",
        ),
        "fidl_files": attr.label_list(
            allow_files = [".fidl"],
            mandatory = True,
            doc = "FIDL interface definition files (can be multiple for imports/includes)",
        ),
        "fdepl_files": attr.label_list(
            allow_files = [".fdepl"],
            mandatory = True,
            doc = "SOME/IP deployment specification files (can be multiple for imports/includes)",
        ),
    },
    doc = "Repository rule that generates CommonAPI code and creates BUILD files",
)

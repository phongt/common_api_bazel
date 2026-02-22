"""
CommonAPI Code Generation Rules for Bazel

This file provides custom rules to generate C++ code from FIDL interface definitions
using the CommonAPI core and SOME/IP generators.
"""

def _commonapi_core_gen_impl(ctx):
    """Implementation of commonapi_core_gen rule"""
    
    fidl_file = ctx.file.fidl
    output_dir = ctx.actions.declare_directory("generated_core")
    config_dir = ctx.actions.declare_directory("eclipse_config_core")
    
    # CommonAPI core generator command format:
    # commonapi-core-generator-linux-x86_64 -data <config_dir> -configuration <config_dir> -d <output_dir> -sk <fidl_file> -sp <search_path>
    # Flags:
    # -data            Eclipse workspace/metadata directory (must be writable)
    # -configuration   Eclipse config directory (must be writable, separate from sandbox home)
    # -d               Output directory for generated code
    # -sk              Generate skeleton code with default postfix
    # -sp              Search path for FIDL/FDEPL resolution
    
    cmd = [
        ctx.file.generator.path,
        "-data",
        config_dir.path,
        "-configuration",
        config_dir.path,
        "-d",
        output_dir.path,
        "-sk",
        fidl_file.path,
        "-sp",
        fidl_file.dirname,
    ]
    
    ctx.actions.run_shell(
        inputs = [fidl_file, ctx.file.generator],
        outputs = [output_dir, config_dir],
        command = "mkdir -p " + config_dir.path + " && " + " ".join(cmd),
        mnemonic = "CommonAPICoreGen",
        progress_message = "Generating CommonAPI core code from %s" % fidl_file.short_path,
        use_default_shell_env = True,
    )
    
    return [
        DefaultInfo(files = depset([output_dir])),
    ]

commonapi_core_gen = rule(
    implementation = _commonapi_core_gen_impl,
    attrs = {
        "fidl": attr.label(
            allow_single_file = [".fidl"],
            mandatory = True,
            doc = "The FIDL interface definition file",
        ),
        "generator": attr.label(
            allow_single_file = True,
            mandatory = True,
            doc = "The CommonAPI core code generator executable",
        ),
    },
    doc = "Generates CommonAPI core C++ code from FIDL interface definition",
)

def _commonapi_someip_gen_impl(ctx):
    """Implementation of commonapi_someip_gen rule"""
    
    fidl_file = ctx.file.fidl
    fdepl_file = ctx.file.fdepl
    output_dir = ctx.actions.declare_directory("generated_someip")
    config_dir = ctx.actions.declare_directory("eclipse_config_someip")
    
    # CommonAPI SOME/IP generator command format:
    # commonapi-someip-generator-linux-x86_64 -data <config_dir> -configuration <config_dir> -d <output_dir> -sp <search_path> <fdepl_file>
    # Flags:
    # -data            Eclipse workspace/metadata directory (must be writable)
    # -configuration   Eclipse config directory (must be writable, separate from sandbox home)
    # -d               Output directory for generated code
    # -sp              Search path for FIDL/FDEPL resolution
    
    fdepl_dir = fdepl_file.dirname
    
    cmd = [
        ctx.file.generator.path,
        "-data",
        config_dir.path,
        "-configuration",
        config_dir.path,
        "-d",
        output_dir.path,
        "-sp",
        fdepl_dir,
        fdepl_file.path,
    ]
    
    ctx.actions.run_shell(
        inputs = [fidl_file, fdepl_file, ctx.file.generator],
        outputs = [output_dir, config_dir],
        command = "mkdir -p " + config_dir.path + " && " + " ".join(cmd),
        mnemonic = "CommonAPISomeIPGen",
        progress_message = "Generating CommonAPI SOME/IP code from %s" % fdepl_file.short_path,
        use_default_shell_env = True,
    )
    
    return [
        DefaultInfo(files = depset([output_dir])),
    ]

commonapi_someip_gen = rule(
    implementation = _commonapi_someip_gen_impl,
    attrs = {
        "fidl": attr.label(
            allow_single_file = [".fidl"],
            mandatory = True,
            doc = "The FIDL interface definition file",
        ),
        "fdepl": attr.label(
            allow_single_file = [".fdepl"],
            mandatory = True,
            doc = "The SOME/IP deployment specification file",
        ),
        "generator": attr.label(
            allow_single_file = True,
            mandatory = True,
            doc = "The CommonAPI SOME/IP code generator executable",
        ),
    },
    doc = "Generates CommonAPI SOME/IP C++ code from FIDL interface and deployment specification",
)

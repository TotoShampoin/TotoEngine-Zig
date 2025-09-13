const std = @import("std");

pub fn build(b: *std.Build) void {
    const run_step = b.step("run", "Run the app");
    const test_step = b.step("test", "Run tests");

    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mod = b.addModule("toto-engine", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,

        .imports = &.{
            .{ .name = "sdl3", .module = b.dependency("sdl3", .{
                .target = target,
                .optimize = optimize,
                .ext_image = true,
                .image_enable_bmp = true,
                .image_enable_gif = true,
                .image_enable_jpg = true,
                .image_enable_lbm = true,
                .image_enable_pcx = true,
                .image_enable_png = true,
                .image_enable_pnm = true,
                .image_enable_qoi = true,
                .image_enable_svg = true,
                .image_enable_tga = true,
                .image_enable_xcf = true,
                .image_enable_xpm = true,
                .image_enable_xv = true,
            }).module("sdl3") },
            .{ .name = "zm", .module = b.dependency("zm", .{}).module("zm") },
        },
    });

    const mod_tests = b.addTest(.{
        .root_module = mod,
    });
    const run_mod_tests = b.addRunArtifact(mod_tests);
    test_step.dependOn(&run_mod_tests.step);

    {
        const exe = b.addExecutable(.{
            .name = "TotoEngine_Zig",
            .root_module = b.createModule(.{
                .root_source_file = b.path("example/main.zig"),
                .target = target,
                .optimize = optimize,

                .imports = &.{
                    .{ .name = "toto-engine", .module = mod },
                },
            }),
        });
        b.installArtifact(exe);

        const run_cmd = b.addRunArtifact(exe);
        run_step.dependOn(&run_cmd.step);
        run_cmd.step.dependOn(b.getInstallStep());
        if (b.args) |args| {
            run_cmd.addArgs(args);
        }

        const exe_tests = b.addTest(.{ .root_module = exe.root_module });
        const run_exe_tests = b.addRunArtifact(exe_tests);
        test_step.dependOn(&run_exe_tests.step);

        const res_dir = b.path("res");
        b.installDirectory(.{
            .source_dir = res_dir,
            .install_dir = .{ .custom = "bin/res" },
            .install_subdir = "",
        });

        mod.addAnonymousImport("shader_vert", .{ .root_source_file = compileShader(b, .vertex, "src/engine/assets/shader.vert", "src/engine/assets/shader.vert.spv") });
        mod.addAnonymousImport("shader_frag", .{ .root_source_file = compileShader(b, .fragment, "src/engine/assets/shader.frag", "src/engine/assets/shader.frag.spv") });
    }
}

pub const ShaderStage = enum {
    vertex,
    fragment,
};
pub fn compileShader(b: *std.Build, comptime stage: ShaderStage, comptime input: [:0]const u8, comptime output: [:0]const u8) std.Build.LazyPath {
    const command = b.addSystemCommand(&.{ "glslc", "-fshader-stage=" ++ @tagName(stage) });
    command.addFileArg(b.path(input));
    command.addArg("-o");
    return command.addOutputFileArg(output);
}

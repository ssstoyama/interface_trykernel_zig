const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = std.zig.CrossTarget{
        .cpu_arch = .thumb,
        .cpu_model = .{ .explicit = &std.Target.arm.cpu.cortex_m0plus },
        .os_tag = .freestanding,
        .abi = .eabi,
        .ofmt = .elf,
    };
    const optimize = b.standardOptimizeOption(.{});

    const boot2 = b.addObject(.{
        .name = "boot2",
        .root_source_file = .{ .path = "src/boot/boot2.zig" },
        .target = target,
        .optimize = optimize,
    });
    const entry = b.addExecutable(.{
        .name = "kernel.elf",
        .root_source_file = .{ .path = "src/entry.zig" },
        .target = target,
        .optimize = optimize,
    });
    entry.addObject(boot2);
    entry.addAssemblyFile("./src/dispatch.S");
    entry.setLinkerScriptPath(.{ .path = "src/linker/pico_memmap.ld" });
    b.installArtifact(entry);

    const elf2uf2_cmd = b.addSystemCommand(&.{
        "tools/elf2uf2",
        "zig-out/bin/kernel.elf",
        "build/kernel.uf2",
    });
    elf2uf2_cmd.step.dependOn(b.getInstallStep());
    const elf2uf2_step = b.step("elf2uf2", "Convert elf to uf2");
    elf2uf2_step.dependOn(&elf2uf2_cmd.step);
}

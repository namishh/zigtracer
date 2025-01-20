const std = @import("std");
const vector = @import("vector.zig");
const ray = @import("ray.zig");
const H = @import("hittable.zig");
const interval = @import("interval.zig");
const camera = @import("camera.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var cam = camera.Camera{};
    cam.initialise();

    var world = H.HittableList.init(allocator);
    defer world.deinit();

    const sphere = H.Sphere.init(vector.Vec3{ 0, 0, -1 }, 0.5);
    try world.add(sphere);

    try cam.render(&world);
}

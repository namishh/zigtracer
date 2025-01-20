const std = @import("std");
const vector = @import("vector.zig");
const ray = @import("ray.zig");
const H = @import("hittable.zig");
const interval = @import("interval.zig");
const material = @import("material.zig");
const camera = @import("camera.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // var cam = camera.Camera{ .aspect_ratio = 1, .image_width = 500 };
    var cam = camera.Camera{};
    cam.initialise();

    var world = H.HittableList.init(allocator);
    defer world.deinit();

    // const avatar_head = H.Sphere.init(vector.Vec3{ 0, 0, -1 }, 0.5);
    // const avatar_body = H.Sphere.init(vector.Vec3{ 0, -2, -1 }, 1.2);

    const sphere_mat = material.Material{
        .dielectric = material.Dielectric.init(1.0 / 1.33),
    };
    const ground_mat = material.Material{ .lambertian = material.Lambertian.init(vector.Vec3{ 0.15, 0.15, 0.15 }) };

    const sphere = H.Sphere.init(vector.Vec3{ 0, 0, -1 }, 0.5, sphere_mat);
    const ground = H.Sphere.init(vector.Vec3{ 0, -100.5, -1 }, 100, ground_mat);

    try world.add(sphere);
    try world.add(ground);

    try cam.render(&world);
}

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

    var cam = camera.Camera{
        .fov = 45,
        .look_from = vector.Vec3{ 0, 0, 2 },
        .look_at = vector.Vec3{ 0, 0, -1 },
    };
    cam.initialise();

    var world = H.HittableList.init(allocator);
    defer world.deinit();
    const sphere_mat = material.Material{
        .metal = material.Metal.init(vector.Vec3{ 0.3, 0.8, 0.9 }, 0.5),
    };
    const sphere_left_mat = material.Material{
        .gradient = material.GradientMaterial.init(vector.Vec3{ 0.2314, 0.4980, 0.9294 }, vector.Vec3{ 0.9294, 0.2314, 0.6863 }),
    };
    const sphere_upperleft_mat = material.Material{
        .gradient = material.GradientMaterial.init(vector.Vec3{ 0.9294, 0.2314, 0.6863 }, vector.Vec3{ 0.2314, 0.4980, 0.9294 }),
    };
    const sphere2_mat = material.Material{
        .metal = material.Metal.init(vector.Vec3{ 0.9, 0.4, 0.4 }, 0),
    };
    const ground_mat = material.Material{ .lambertian = material.Lambertian.init(vector.Vec3{ 0.08, 0.08, 0.08 }) };

    const sphere_bubble_mat = material.Material{
        .dielectric = material.Dielectric.init(1.0 / 1.5),
    };

    const sphere_right_mat = material.Material{
        .dielectric = material.Dielectric.init(1.5),
    };

    const sphere_left = H.Sphere.init(vector.Vec3{ -1.38, 0.12, -1 }, 0.45, sphere_left_mat);
    const sphere_upperleft = H.Sphere.init(vector.Vec3{ -1.38, 0.75, -0.95 }, 0.25, sphere_upperleft_mat);
    const sphere = H.Sphere.init(vector.Vec3{ 0.37, 0, -1 }, 0.35, sphere_mat);
    const sphere2 = H.Sphere.init(vector.Vec3{ -0.43, 0, -1 }, 0.35, sphere2_mat);
    const sphere_right = H.Sphere.init(vector.Vec3{ 1.32, 0.45, -1 }, 0.55, sphere_right_mat);
    const sphere_bubble = H.Sphere.init(vector.Vec3{ 1.32, 0.45, -1 }, 0.45, sphere_bubble_mat);
    const ground = H.Sphere.init(vector.Vec3{ 0, -100.35, -1 }, 100, ground_mat);

    try world.add(sphere_left);
    try world.add(sphere_upperleft);
    try world.add(sphere);
    try world.add(sphere2);
    try world.add(sphere_right);
    try world.add(sphere_bubble);
    try world.add(ground);

    try cam.render(&world);
}

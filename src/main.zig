const std = @import("std");
const vector = @import("vector.zig");
const ray = @import("ray.zig");
const H = @import("hittable.zig");

pub fn ray_color(r: ray.Ray, world: H.HittableList) vector.Vec3 {
    var rec = H.HitRecord.init();
    if (world.hit(r, 0.001, std.math.inf(f32), &rec)) {
        // Return a color based on the sphere's normal
        return vector.scalar_mul(vector.add(rec.normal, vector.Vec3{ 1, 1, 1 }), 0.5);
    }
    const stripe_width = 0.1;
    const angle = std.math.pi / 4.0;
    const x = r.direction[0];
    const y = r.direction[1];

    const rotated_x = x * @cos(angle) - y * @sin(angle);
    const stripe_value = @mod(rotated_x + 10.0, 2.0 * stripe_width);

    if (stripe_value < stripe_width) {
        return vector.Vec3{ 1.0, 1.0, 1.0 };
    } else {
        return vector.Vec3{ 0.0, 0.0, 0.0 };
    }
}

pub fn write_color(file: std.fs.File, pixel_color: vector.Vec3) !void {
    const r = @max(0.0, @min(1.0, pixel_color[0]));
    const g = @max(0.0, @min(1.0, pixel_color[1]));
    const b = @max(0.0, @min(1.0, pixel_color[2]));

    const rbyte = @as(u8, @intFromFloat(r * 255.999));
    const gbyte = @as(u8, @intFromFloat(g * 255.999));
    const bbyte = @as(u8, @intFromFloat(b * 255.999));

    try file.writer().print("{d} {d} {d}\n", .{ rbyte, gbyte, bbyte });
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const aspect_ratio = 16.0 / 9.0;
    const image_width = 800;
    const image_height = @max(@as(u32, @intFromFloat(@as(f32, @floatFromInt(image_width)) / aspect_ratio)), 1);

    const viewport_height = 2.0;
    const viewport_width = aspect_ratio * viewport_height;
    const focal_length = 1.0;

    const origin = vector.Vec3{ 0, 0, 0 };
    const horizontal = vector.Vec3{ viewport_width, 0, 0 };
    const vertical = vector.Vec3{ 0, viewport_height, 0 };
    const lower_left_corner = vector.sub(vector.sub(vector.sub(origin, vector.div(horizontal, 2.0)), vector.div(vertical, 2.0)), vector.Vec3{ 0, 0, focal_length });

    var world = H.HittableList.init(allocator);
    defer world.deinit();

    const sphere = H.Sphere.init(vector.Vec3{ 0, 0, -1 }, 0.5);
    try world.add(sphere);

    const file = try std.fs.cwd().createFile("image.ppm", .{});
    defer file.close();

    try file.writer().print("P3\n{d} {d}\n255\n", .{ image_width, image_height });

    for (0..image_height) |j| {
        for (0..image_width) |i| {
            const u = @as(f32, @floatFromInt(i)) / (image_width - 1);
            const v = @as(f32, @floatFromInt(image_height - j - 1)) / (image_height - 1);

            const direction = vector.add(lower_left_corner, vector.add(vector.scalar_mul(horizontal, u), vector.scalar_mul(vertical, v)));
            const r = ray.Ray{ .origin = origin, .direction = direction };

            const pixel_color = ray_color(r, world);
            try write_color(file, pixel_color);
        }
    }
}

const std = @import("std");
const vector = @import("vector.zig");
const ray = @import("ray.zig");

pub fn hit_sphere(center: vector.Vec3, radius: f32, r: ray.Ray) bool {
    const oc = vector.sub(r.origin, center);
    const a = vector.dot(r.direction, r.direction);
    const b = 2.0 * vector.dot(oc, r.direction);
    const c = vector.dot(oc, oc) - radius * radius;
    const discriminant = b * b - 4.0 * a * c;
    return discriminant > 0.0;
}

// returns a color
pub fn ray_color(r: ray.Ray) vector.Vec3 {
    if (hit_sphere(vector.Vec3{ 0, 0, -1 }, 0.5, r)) {
        return vector.Vec3{ 1, 0, 0 };
    }
    const unit_d = vector.unit_vector(r.direction);
    const a = 0.5 * (unit_d[1] + 1.0);
    return vector.add(vector.scalar_mul(vector.Vec3{ 1, 1, 1 }, 1.0 - a), vector.scalar_mul(vector.Vec3{ 0.5, 0.7, 1.0 }, a));
}

pub fn write_color(file: std.fs.File, c: vector.Vec3) !void {
    const r = c[0];
    const g = c[1];
    const b = c[2];

    const rbyte = @as(u8, @intFromFloat(r * 255.0));
    const gbyte = @as(u8, @intFromFloat(g * 255.0));
    const bbyte = @as(u8, @intFromFloat(b * 255.0));

    try file.writer().print("{d} {d} {d}\n", .{ rbyte, gbyte, bbyte });
}
pub fn main() !void {
    const aspect_ratio = 16.0 / 9.0;
    const image_width = 512;
    const image_height = @max(@as(u32, @round(@as(f32, @floatFromInt(image_width)) / aspect_ratio)), 1);

    // camera settings
    const focal_length = 1.0;
    const viewport_height = 2.0;
    const viewport_width = aspect_ratio * viewport_height;
    const camera_center = vector.Vec3{ 0, 0, 0 };

    // calculate the vectors across the horizontal and down the vertical viewport edges
    const viewport_u = vector.Vec3{ viewport_width, 0, 0 };
    const viewport_v = vector.Vec3{ 0, -viewport_height, 0 };

    const pixel_delta_u = vector.div(viewport_u, @as(f32, @floatFromInt(image_width)));
    const pixel_delta_v = vector.div(viewport_v, @as(f32, @floatFromInt(image_height)));

    const viewport_upper_left = vector.sub(vector.sub(camera_center, vector.Vec3{ 0, 0, focal_length }), vector.add(vector.div(viewport_u, 2.0), vector.div(viewport_v, 2.0)));
    const pixel00_loc = vector.add(viewport_upper_left, vector.scalar_mul(vector.add(pixel_delta_u, pixel_delta_v), 0.5));

    const file = try std.fs.cwd().createFile(
        "image.ppm",
        .{ .read = true },
    );
    defer file.close();

    // ppm header
    try file.writer().print("P3\n{d} {d}\n255\n", .{ image_width, image_height });

    var i: u32 = 0;
    while (i < image_height) : (i += 1) {
        var j: u32 = 0;
        while (j < image_width) : (j += 1) {
            const pixel_center = vector.add(vector.add(pixel00_loc, vector.scalar_mul(pixel_delta_u, @as(f32, @floatFromInt(j)))), vector.scalar_mul(pixel_delta_v, @as(f32, @floatFromInt(i))));
            const ray_direction = vector.sub(pixel_center, camera_center);
            const r = ray.Ray{
                .origin = camera_center,
                .direction = ray_direction,
            };
            const pixel_col = ray_color(r);

            try write_color(file, pixel_col);
        }
    }
}

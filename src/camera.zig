const std = @import("std");
const vector = @import("vector.zig");
const ray = @import("ray.zig");
const interval = @import("interval.zig");
const H = @import("hittable.zig");

pub fn write_color(file: std.fs.File, pixel_color: vector.Vec3) !void {
    const r = @max(0.0, @min(1.0, pixel_color[0]));
    const g = @max(0.0, @min(1.0, pixel_color[1]));
    const b = @max(0.0, @min(1.0, pixel_color[2]));

    const rbyte = @as(u8, @intFromFloat(r * 255.999));
    const gbyte = @as(u8, @intFromFloat(g * 255.999));
    const bbyte = @as(u8, @intFromFloat(b * 255.999));

    try file.writer().print("{d} {d} {d}\n", .{ rbyte, gbyte, bbyte });
}

pub fn ray_color(r: ray.Ray, world: *const H.HittableList) vector.Vec3 {
    var rec = H.HitRecord.init();
    if (world.hit(r, interval.Interval{ .min = 0.001, .max = std.math.inf(f64) }, &rec)) {
        return vector.scalar_mul(vector.add(rec.normal, vector.Vec3{ 1, 1, 1 }), 0.5);
    }
    const stripe_width = 0.08;
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

pub const Camera = struct {
    aspect_ratio: f64 = 16.0 / 9.0,
    image_width: u32 = 512,
    image_height: u32 = undefined,
    center: vector.Vec3 = undefined,
    pixel00_loc: vector.Vec3 = undefined,
    pixel_delta_u: vector.Vec3 = undefined,
    pixel_delta_v: vector.Vec3 = undefined,

    pub fn initialise(self: *Camera) void {
        self.image_height = @max(@as(u32, @intFromFloat(@as(f32, @floatFromInt(self.image_width)) / self.aspect_ratio)), 1);

        self.center = vector.Vec3{ 0, 0, 0 };

        const focal_length = 1.0;
        const viewport_height = 2.0;
        const viewport_width = viewport_height * (@as(f64, @floatFromInt(self.image_width)) / @as(f64, @floatFromInt(self.image_height)));

        const viewport_u = vector.Vec3{ viewport_width, 0, 0 };
        const viewport_v = vector.Vec3{ 0, -viewport_height, 0 };

        self.pixel_delta_u = vector.div(viewport_u, @as(f64, @floatFromInt(self.image_width)));
        self.pixel_delta_v = vector.div(viewport_v, @as(f64, @floatFromInt(self.image_height)));

        const viewport_upper_left = vector.sub(vector.sub(self.center, vector.Vec3{ 0, 0, focal_length }), vector.div(vector.add(viewport_u, viewport_v), 2.0));
        self.pixel00_loc = vector.add(viewport_upper_left, vector.div(vector.add(self.pixel_delta_u, self.pixel_delta_v), 2.0));
    }

    pub fn render(self: *Camera, world: *const H.HittableList) !void {
        self.initialise();
        const file = try std.fs.cwd().createFile("image.ppm", .{});
        defer file.close();

        try file.writer().print("P3\n{} {}\n255\n", .{ self.image_width, self.image_height });

        for (0..self.image_height) |j| {
            for (0..self.image_width) |i| {
                const uscaled = vector.scalar_mul(self.pixel_delta_u, @as(f64, @floatFromInt(i)));
                const vscaled = vector.scalar_mul(self.pixel_delta_v, @as(f64, @floatFromInt(j)));
                const pixel_center = vector.add(self.pixel00_loc, vector.add(uscaled, vscaled));
                const ray_direction = vector.sub(pixel_center, self.center);
                const r = ray.Ray{ .origin = self.center, .direction = ray_direction };

                const pixel_color = ray_color(r, world);
                try write_color(file, pixel_color);
            }
        }
    }
};

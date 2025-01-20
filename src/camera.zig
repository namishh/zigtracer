const std = @import("std");
const vector = @import("vector.zig");
const ray = @import("ray.zig");
const interval = @import("interval.zig");
const H = @import("hittable.zig");

pub fn randomDouble() f32 {
    const rand = std.crypto.random;
    const a = rand.float(f32);
    return a;
}

pub fn write_color(file: std.fs.File, pixel_color: vector.Vec3) !void {
    const r = linear_to_gamma(pixel_color[0]);
    const g = linear_to_gamma(pixel_color[1]);
    const b = linear_to_gamma(pixel_color[2]);

    const intensity = interval.Interval{ .min = 0.0, .max = 0.999 };

    const rbyte = @as(u8, @intFromFloat(intensity.clamp(r) * 256));
    const gbyte = @as(u8, @intFromFloat(intensity.clamp(g) * 256));
    const bbyte = @as(u8, @intFromFloat(intensity.clamp(b) * 256));

    try file.writer().print("{d} {d} {d}\n", .{ rbyte, gbyte, bbyte });
}

pub fn linear_to_gamma(n: f32) f32 {
    if (n > 0) return @sqrt(n);
    return n;
}

pub fn ray_color(r: ray.Ray, depth: u32, world: *const H.HittableList) vector.Vec3 {
    if (depth <= 0) {
        return vector.Vec3{ 0, 0, 0 };
    }

    var rec = H.HitRecord.init();
    if (world.hit(r, interval.Interval{ .min = 0.001, .max = std.math.inf(f32) }, &rec)) {
        // const direction = vector.add(rec.normal, vector.randomUnitVector());
        // return vector.scalar_mul(ray_color(ray.Ray{ .origin = rec.p, .direction = direction }, depth - 1, world), 0.1);
        var scatterd = ray.Ray{ .direction = vector.Vec3{ 0, 0, 0 }, .origin = vector.Vec3{ 0, 0, 0 } };
        var attenuation = vector.Vec3{ 0, 0, 0 };
        if (rec.mat.scatter(r, rec, &attenuation, &scatterd)) {
            return vector.mul(ray_color(scatterd, depth - 1, world), attenuation);
        } else {
            return vector.Vec3{ 0, 0, 0 };
        }
    }
    const x = r.direction[0];
    const y = r.direction[1];

    const rotated_x = x * @cos(std.math.pi / 4.0) - y * @sin(std.math.pi / 4.0);
    const rotated_y = x * @sin(std.math.pi / 4.0) + y * @cos(std.math.pi / 4.0);

    const cell_size = 0.1;
    const cell_x = @floor(rotated_x / cell_size);
    const cell_y = @floor(rotated_y / cell_size);

    if (@mod(cell_x + cell_y, 2) == 0) {
        return vector.Vec3{ 0.98, 0.98, 0.98 }; // White
    } else {
        return vector.Vec3{ 0.02, 0.02, 0.02 }; // Black
    }
}

pub fn sample_square() vector.Vec3 {
    return vector.Vec3{ randomDouble() - 0.5, randomDouble() - 0.5, 0.0 };
}

pub const Camera = struct {
    aspect_ratio: f32 = 16.0 / 9.0,
    image_width: u32 = 960,
    samples_per_pixel: f32 = 100,
    max_depth: u32 = 50,
    fov: u32 = 20,
    look_from: vector.Vec3 = vector.Vec3{ 0, 0, 1 },
    look_at: vector.Vec3 = vector.Vec3{ 0, 0, -1 },
    vup: vector.Vec3 = vector.Vec3{ 0, 1, 0 },
    u: vector.Vec3 = vector.Vec3{ 0, 0, 0 },
    v: vector.Vec3 = vector.Vec3{ 0, 0, 0 },
    w: vector.Vec3 = vector.Vec3{ 0, 0, 0 },

    image_height: u32 = undefined,
    center: vector.Vec3 = undefined,
    pixel00_loc: vector.Vec3 = undefined,
    pixel_delta_u: vector.Vec3 = undefined,
    pixel_delta_v: vector.Vec3 = undefined,
    pixel_samples_scale: f32 = undefined,

    pub fn initialise(self: *Camera) void {
        self.image_height = @max(@as(u32, @intFromFloat(@as(f32, @floatFromInt(self.image_width)) / self.aspect_ratio)), 1);
        self.pixel_samples_scale = 1.0 / self.samples_per_pixel;
        self.center = self.look_from;

        const focal_length = vector.len(vector.sub(self.look_from, self.look_at));
        const theta = std.math.degreesToRadians(@as(f32, @floatFromInt(self.fov)));
        const h = std.math.tan(theta / 2.0);

        const viewport_height = 2.0 * h * focal_length;
        const viewport_width = viewport_height * (@as(f32, @floatFromInt(self.image_width)) / @as(f32, @floatFromInt(self.image_height)));

        self.w = vector.unit_vector(vector.sub(self.look_from, self.look_at));
        self.u = vector.unit_vector(vector.cross(self.vup, self.w));
        self.v = vector.cross(self.w, self.u);

        const viewport_u = vector.scalar_mul(self.u, viewport_width);
        const viewport_v = vector.scalar_mul(vector.negative(self.v), viewport_height);

        self.pixel_delta_u = vector.div(viewport_u, @as(f32, @floatFromInt(self.image_width)));
        self.pixel_delta_v = vector.div(viewport_v, @as(f32, @floatFromInt(self.image_height)));

        //         auto viewport_upper_left = center - (focal_length * w) - viewport_u/2 - viewport_v/2;

        const viewport_upper_left = vector.sub(vector.sub(self.center, vector.scalar_mul(self.w, focal_length)), vector.div(vector.add(viewport_u, viewport_v), 2.0));
        self.pixel00_loc = vector.add(viewport_upper_left, vector.div(vector.add(self.pixel_delta_u, self.pixel_delta_v), 2.0));
    }

    pub fn render(self: *Camera, world: *const H.HittableList) !void {
        self.initialise();
        const file = try std.fs.cwd().createFile("image.ppm", .{});
        defer file.close();

        try file.writer().print("P3\n{} {}\n255\n", .{ self.image_width, self.image_height });

        for (0..self.image_height) |j| {
            for (0..self.image_width) |i| {
                var pixel_color = vector.Vec3{ 0, 0, 0 };
                for (0..@intFromFloat(self.samples_per_pixel)) |_| {
                    const r = self.get_ray(i, j);
                    pixel_color = vector.add(pixel_color, ray_color(r, self.max_depth, world));
                }
                try write_color(file, vector.scalar_mul(pixel_color, self.pixel_samples_scale));
            }
        }
    }

    pub fn get_ray(self: *Camera, i: usize, j: usize) ray.Ray {
        const offset = sample_square();
        const t1 = vector.scalar_mul(self.pixel_delta_u, @as(f32, @floatFromInt(i)) + offset[0]);
        const t2 = vector.scalar_mul(self.pixel_delta_v, @as(f32, @floatFromInt(j)) + offset[1]);
        const pixel_center = vector.add(self.pixel00_loc, vector.add(t1, t2));

        const ray_origin = self.center;
        const ray_direction = vector.sub(pixel_center, ray_origin);
        return ray.Ray{ .origin = ray_origin, .direction = ray_direction };
    }
};

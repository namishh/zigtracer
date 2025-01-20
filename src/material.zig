// material.zig
const std = @import("std");
const vector = @import("vector.zig");
const ray = @import("ray.zig");
const H = @import("hittable.zig");
const Vec3 = vector.Vec3;
const Ray = ray.Ray;
const HitRecord = H.HitRecord;

pub const Material = union(enum) {
    lambertian: Lambertian,
    metal: Metal,

    pub fn scatter(self: Material, r_in: Ray, rec: HitRecord, attenuation: *Vec3, scattered: *Ray) bool {
        return switch (self) {
            .lambertian => |lambertian| lambertian.scatter(rec, attenuation, scattered),
            .metal => |metal| metal.scatter(r_in, rec, attenuation, scattered),
        };
    }
};

pub const Lambertian = struct {
    albedo: Vec3,

    pub fn init(albedo: Vec3) Lambertian {
        return .{ .albedo = albedo };
    }

    pub fn scatter(self: Lambertian, rec: HitRecord, attenuation: *Vec3, scattered: *Ray) bool {
        var scatter_direction = vector.add(rec.normal, vector.randomUnitVector());
        if (vector.near_zero(scatter_direction)) {
            scatter_direction = rec.normal;
        }
        scattered.* = Ray{ .origin = rec.p, .direction = scatter_direction };
        attenuation.* = self.albedo;
        return true;
    }
};

pub const Metal = struct {
    albedo: Vec3,
    fuzz: f32,

    pub fn init(albedo: Vec3, fuzz: f32) Metal {
        return .{
            .albedo = albedo,
            .fuzz = if (fuzz < 1) fuzz else 1,
        };
    }

    pub fn scatter(self: Metal, r_in: Ray, rec: HitRecord, attenuation: *Vec3, scattered: *Ray) bool {
        const reflected = vector.reflect(r_in.direction, rec.normal);
        const fuzzed_reflected = vector.add(
            vector.unit_vector(reflected),
            vector.scalar_mul(vector.randomUnitVector(), self.fuzz),
        );
        scattered.* = Ray{ .origin = rec.p, .direction = fuzzed_reflected };
        attenuation.* = self.albedo;

        return vector.dot(scattered.direction, rec.normal) > 0;
    }
};

// material.zig
const std = @import("std");
const vector = @import("vector.zig");
const ray = @import("ray.zig");
const H = @import("hittable.zig");
const Vec3 = vector.Vec3;
const Ray = ray.Ray;
const HitRecord = H.HitRecord;

fn reflectance(cosine: f32, ref_idx: f32) f32 {
    var r0 = (1 - ref_idx) / (1 + ref_idx);
    r0 = r0 * r0;
    return r0 + (1 - r0) * (1 - cosine) * (1 - cosine) * (1 - cosine) * (1 - cosine) * (1 - cosine);
}

pub const Material = union(enum) {
    lambertian: Lambertian,
    metal: Metal,
    dielectric: Dielectric,

    pub fn scatter(self: Material, r_in: Ray, rec: HitRecord, attenuation: *Vec3, scattered: *Ray) bool {
        return switch (self) {
            .lambertian => |lambertian| lambertian.scatter(rec, attenuation, scattered),
            .metal => |metal| metal.scatter(r_in, rec, attenuation, scattered),
            .dielectric => |dielectric| dielectric.scatter(r_in, rec, attenuation, scattered),
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

pub const Dielectric = struct {
    refractive_index: f32,

    pub fn init(refractive_index: f32) Dielectric {
        return .{ .refractive_index = refractive_index };
    }

    pub fn scatter(self: Dielectric, r_in: Ray, rec: HitRecord, attenuation: *Vec3, scattered: *Ray) bool {
        attenuation.* = Vec3{ 1.0, 1.0, 1.0 };

        const ri = if (rec.front_face) 1.0 / self.refractive_index else self.refractive_index;
        const unit_direction = vector.unit_vector(r_in.direction);

        const cos_theta = @min(vector.dot(-unit_direction, rec.normal), 1.0);
        const sin_theta = @sqrt(1.0 - cos_theta * cos_theta);

        var direction = Vec3{ 0, 0, 0 };

        const cannot_refract = ri * sin_theta > 1.0;

        if (cannot_refract or reflectance(cos_theta, ri) > 0.5) {
            direction = vector.reflect(unit_direction, rec.normal);
        } else {
            direction = vector.refract(unit_direction, rec.normal, ri);
        }
        scattered.* = Ray{ .direction = rec.p, .origin = direction };

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

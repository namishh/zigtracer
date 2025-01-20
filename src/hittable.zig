const std = @import("std");
const vector = @import("vector.zig");
const ray = @import("ray.zig");
const interval = @import("interval.zig");
const material = @import("material.zig");
const Vec3 = vector.Vec3;
const Ray = ray.Ray;

pub const HitRecord = struct {
    p: Vec3,
    normal: Vec3,
    t: f32,
    mat: material.Material = undefined,
    front_face: bool,

    pub fn init() HitRecord {
        return .{
            .p = Vec3{ 0, 0, 0 },
            .normal = Vec3{ 0, 0, 0 },
            .t = 0,
            .front_face = false,
        };
    }

    pub fn set_face_normal(self: *HitRecord, r: Ray, outward_normal: Vec3) void {
        self.front_face = vector.dot(r.direction, outward_normal) < 0;
        self.normal = if (self.front_face) outward_normal else vector.negative(outward_normal);
    }
};

pub const Sphere = struct {
    center: Vec3,
    radius: f32,
    mat: material.Material,

    pub fn init(center: Vec3, radius: f32, mat: material.Material) Sphere {
        return .{
            .center = center,
            .radius = radius,
            .mat = mat,
        };
    }

    pub fn hit(self: Sphere, r: Ray, t: interval.Interval, rec: *HitRecord) bool {
        const oc = vector.sub(r.origin, self.center);
        const a = vector.len_squared(r.direction);
        const half_b = vector.dot(oc, r.direction);
        const c = vector.len_squared(oc) - self.radius * self.radius;

        const discriminant = half_b * half_b - a * c;
        if (discriminant < 0) return false;
        const sqrtd = @sqrt(discriminant);

        var root = (-half_b - sqrtd) / a;
        if (!t.surrounds(root)) {
            root = (-half_b + sqrtd) / a;
            if (!t.surrounds(root)) {
                return false;
            }
        }

        rec.t = root;
        rec.p = r.at(rec.t);
        const outward_normal = vector.div(vector.sub(rec.p, self.center), self.radius);
        rec.set_face_normal(r, outward_normal);
        rec.mat = self.mat;
        return true;
    }
};

pub const HittableList = struct {
    objects: std.ArrayList(Sphere),
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) HittableList {
        return .{
            .objects = std.ArrayList(Sphere).init(allocator),
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *HittableList) void {
        self.objects.deinit();
    }

    pub fn add(self: *HittableList, object: Sphere) !void {
        try self.objects.append(object);
    }

    pub fn hit(self: HittableList, r: Ray, t: interval.Interval, rec: *HitRecord) bool {
        var temp_rec = HitRecord.init();
        var hit_anything = false;
        var closest_so_far = t.max;

        for (self.objects.items) |object| {
            if (object.hit(r, interval.Interval{ .min = t.min, .max = closest_so_far }, &temp_rec)) {
                hit_anything = true;
                closest_so_far = temp_rec.t;
                rec.* = temp_rec;
            }
        }

        return hit_anything;
    }
};

const std = @import("std");
const math = std.math;

pub const Vec3 = @Vector(3, f64);

pub inline fn dot(v1: Vec3, v2: Vec3) f64 {
    return @reduce(.Add, v1 * v2);
}

pub inline fn len(v: Vec3) f64 {
    return math.sqrt(dot(v, v));
}

pub inline fn len_squared(v: Vec3) f64 {
    return v[0] * v[0] + v[1] * v[1] + v[2] * v[2];
}

pub inline fn unit_vector(v: Vec3) Vec3 {
    return div(v, len(v));
}

pub inline fn cross(v1: Vec3, v2: Vec3) Vec3 {
    return Vec3{
        v1[1] * v2[2] - v1[2] * v2[1],
        v1[2] * v2[0] - v1[0] * v2[2],
        v1[0] * v2[1] - v1[1] * v2[0],
    };
}

pub inline fn div(v: Vec3, scalar: f64) Vec3 {
    return Vec3{
        v[0] / scalar,
        v[1] / scalar,
        v[2] / scalar,
    };
}

pub inline fn scalar_mul(v: Vec3, scalar: f64) Vec3 {
    return Vec3{
        v[0] * scalar,
        v[1] * scalar,
        v[2] * scalar,
    };
}

pub inline fn add(v1: Vec3, v2: Vec3) Vec3 {
    return Vec3{
        v1[0] + v2[0],
        v1[1] + v2[1],
        v1[2] + v2[2],
    };
}

pub inline fn sub(v1: Vec3, v2: Vec3) Vec3 {
    return Vec3{
        v1[0] - v2[0],
        v1[1] - v2[1],
        v1[2] - v2[2],
    };
}

pub inline fn mul(v1: Vec3, v2: Vec3) Vec3 {
    return Vec3{
        v1[0] * v2[0],
        v1[1] * v2[1],
        v1[2] * v2[2],
    };
}

pub inline fn negative(v: Vec3) Vec3 {
    return Vec3{
        -v[0],
        -v[1],
        -v[2],
    };
}

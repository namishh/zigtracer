const std = @import("std");
const math = std.math;

pub const Vec3 = @Vector(3, f32);

pub fn randomDouble() f32 {
    const rand = std.crypto.random;
    const a = rand.float(f32);
    return a;
}

pub inline fn randomDoubleRange(min: f32, max: f32) f32 {
    return min + (max - min) * randomDouble();
}

pub fn random() Vec3 {
    return Vec3{ randomDouble(), randomDouble(), randomDouble() };
}

pub fn randomRange(min: f32, max: f32) Vec3 {
    return Vec3{ randomDoubleRange(min, max), randomDoubleRange(min, max), randomDoubleRange(min, max) };
}

pub inline fn randomUnitVector() Vec3 {
    while (true) {
        const p = randomRange(-1.0, 1.0);
        const q = len_squared(p);
        if (1e-160 < q and q < 1.0) {
            return div(p, @sqrt(q));
        }
    }
}

pub inline fn randomOnHemisphere(v: Vec3) Vec3 {
    const ran = randomUnitVector();
    if (dot(ran, v) > 0.0) {
        return ran;
    }
    return negative(ran);
}

pub inline fn dot(v1: Vec3, v2: Vec3) f32 {
    return @reduce(.Add, v1 * v2);
}

pub inline fn len(v: Vec3) f32 {
    return math.sqrt(dot(v, v));
}

pub inline fn len_squared(v: Vec3) f32 {
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

pub inline fn div(v: Vec3, scalar: f32) Vec3 {
    return Vec3{
        v[0] / scalar,
        v[1] / scalar,
        v[2] / scalar,
    };
}

pub inline fn scalar_mul(v: Vec3, scalar: f32) Vec3 {
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

pub inline fn reflect(v: Vec3, n: Vec3) Vec3 {
    return sub(v, scalar_mul(n, 2.0 * dot(v, n)));
}

pub inline fn near_zero(v: Vec3) bool {
    const s = 1e-8;
    return @abs(v[0]) < s and @abs(v[1]) < s and @abs(v[2]) < s;
}

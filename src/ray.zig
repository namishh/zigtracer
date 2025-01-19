const vector = @import("vector.zig");

pub const Ray = struct {
    origin: vector.Vec3,
    direction: vector.Vec3,
    const Self = @This();

    pub fn at(self: Self, t: f32) vector.Vec3 {
        return self.origin + self.direction * t;
    }
};

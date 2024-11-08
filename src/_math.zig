pub const Vec2i = struct {
    x: i32,
    y: i32,

    pub fn add(self: Vec2i, other: Vec2i) Vec2i {
        return Vec2i{
            .x = self.x + other.x,
            .y = self.y + other.y,
        };
    }
};

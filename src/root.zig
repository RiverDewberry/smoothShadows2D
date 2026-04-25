const std = @import("std");
const Io = std.Io;

const rl = @import("raylib");

var shadowShader: ?rl.Shader = null;

pub const ShadowData = struct {
    baseTexture: rl.Texture,
    source: rl.Rectangle,
    dest: rl.Rectangle,

    pub fn init(
        texture: rl.Texture,
        source: rl.Rectangle,
        dest: rl.Rectangle
    ) ShadowData
    {
        return ShadowData{
            .source = source,
            .dest = dest,
            .baseTexture = texture
        };
    }

    pub fn drawShadows(self: ShadowData) void
    {
        rl.beginShaderMode(shadowShader.?);
   
        self.baseTexture.drawPro(
            self.source,
            self.dest,
            rl.Vector2{.x = 0, .y = 0},
            0,
            rl.Color.white
        );

        rl.endShaderMode();
    }
};

///compiles and loads shadow shader, must be called before drawing shadows
pub fn initShadowShader() !void
{
    shadowShader = try rl.loadShader(null, "./shader/shadows.fs");
}

///unloads shadow shader
pub fn deinitShadowShader() void {
    if (shadowShader) |shader|
    {
        rl.unloadShader(shader);
        shadowShader = null;
    }
}

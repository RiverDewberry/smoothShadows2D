const std = @import("std");
const Io = std.Io;

const rl = @import("raylib");

var shadowShader: ?rl.Shader = null;

pub const ShadowPaneChain = struct {
    color: rl.Color,
    vecs: []rl.Vector2,

    pub fn init(
        color: rl.Color,
        vecs: []rl.Vector2
    ) ShadowPaneChain
    {
        return ShadowPaneChain {
            .color = color,
            .vecs = vecs
        };
    }
};

pub const LightPane = struct {
    focus: f32,
    start: rl.Vector2,
    end: rl.Vector2,
    color: rl.Color,

    pub fn init(
        focus: f32,
        start: rl.Vector2,
        end: rl.Vector2,
        color: rl.Color
    ) LightPane
    {
        return LightPane {
            .focus = focus,
            .start = start,
            .end = end,
            .color = color
        };
    }
};

pub const ShadowData = struct {
    baseTexture: rl.Texture,
    source: rl.Rectangle,
    dest: rl.Rectangle,
    lights: []LightPane,

    pub fn init(
        texture: rl.Texture,
        source: rl.Rectangle,
        dest: rl.Rectangle,
        lights: []LightPane
    ) ShadowData
    {
        return ShadowData{
            .source = source,
            .dest = dest,
            .baseTexture = texture,
            .lights = lights
        };
    }

    pub fn drawShadows(self: ShadowData) void
    {
        rl.beginShaderMode(shadowShader.?);

        const positionLocation = rl.getShaderLocation(
            shadowShader.?, "position"
            );
        rl.setShaderValue(
            shadowShader.?, positionLocation, 
            &[4]f32{self.dest.x, self.dest.y, self.dest.width, self.dest.height},
            rl.ShaderUniformDataType.vec4);

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

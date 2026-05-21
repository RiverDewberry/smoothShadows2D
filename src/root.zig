const std = @import("std");
const Io = std.Io;

const rl = @import("raylib");

var shadowShader: ?rl.Shader = null;
var lightAreaShader: ?rl.Shader = null;
var shadowAreaShader: ?rl.Shader = null;

pub const ShadowPane= struct {
    color: rl.Color,
    start: rl.Vector2,
    end: rl.Vector2,

    pub fn init(
        color: rl.Color,
        start: rl.Vector2,
        end: rl.Vector2,
    ) ShadowPane
    {
        return ShadowPane{
            .color = color,
            .start = start,
            .end = end
        };
    }
};

pub const LightPane = struct {
    focus: f32,
    start: rl.Vector2,
    end: rl.Vector2,
    color: rl.Color,
    cache: rl.RenderTexture,

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
            .color = color,
            .cache = undefined
        };
    }
};

pub const ShadowData = struct {
    baseTexture: rl.Texture,
    source: rl.Rectangle,
    dest: rl.Rectangle,
    lights: []LightPane,
    redrawArea: rl.RenderTexture,

    pub fn init(
        texture: rl.Texture,
        source: rl.Rectangle,
        dest: rl.Rectangle,
        lights: []LightPane,
    ) !ShadowData
    {
        var retval = ShadowData{
            .source = source,
            .dest = dest,
            .baseTexture = texture,
            .lights = lights,
            .redrawArea = try rl.RenderTexture.init(
                @trunc(dest.width),
                @trunc(dest.height))
        };

        retval.redrawArea.begin();
        rl.clearBackground(rl.Color.black);
        retval.redrawArea.end();

        for (lights, 0..) |_, i|
        {
            retval.lights[i].cache = try rl.RenderTexture.init(
                @trunc(dest.width),
                @trunc(dest.height));
            retval.lights[i].cache.begin();
            rl.clearBackground(rl.Color.black);
            retval.lights[i].cache.end();
            retval.addLightArea(i);
            retval.recalculateLight(i);
        }

        return retval;
    }

    pub fn deinit(self: ShadowData) void
    {
        for (self.lights) |light|
        {
            light.cache.unload();
        }
        self.redrawArea.unload();
    }

    pub fn recalculateLight(self: ShadowData, lightNum: usize) void
    {
        rl.beginShaderMode(shadowShader.?);

        const positionLocation = rl.getShaderLocation(
            shadowShader.?, "position");
        rl.setShaderValue(
            shadowShader.?, positionLocation, 
            &[4]f32{self.dest.x, self.dest.y, self.dest.width, self.dest.height},
            rl.ShaderUniformDataType.vec4);

        const lightColorLocation = rl.getShaderLocation(
            shadowShader.?, "lightColor");
        const lightPositionLocation = rl.getShaderLocation(
            shadowShader.?, "lightPosition");

        const light = self.lights[lightNum];
        light.cache.begin();
        const lightColor = light.color.normalize();

        rl.setShaderValue(
            shadowShader.?, lightPositionLocation, 
            &[4]f32{light.start.x, light.start.y, light.end.x, light.end.y},
            rl.ShaderUniformDataType.vec4);
        rl.setShaderValue(
            shadowShader.?, lightColorLocation, 
            &[4]f32{lightColor.x, lightColor.y, lightColor.z, light.focus},
            rl.ShaderUniformDataType.vec4);

        self.redrawArea.texture.draw(
            0, 0,
            rl.Color.white
        );

        rl.endShaderMode();
        light.cache.end();

        self.redrawArea.begin();
        rl.clearBackground(rl.Color.black);
        self.redrawArea.end();
    }

    pub fn addLightArea(self: ShadowData, lightNum: usize) void
    {
        const light = self.lights[lightNum];

        self.redrawArea.begin();
        rl.beginShaderMode(lightAreaShader.?);

        const positionLocation = rl.getShaderLocation(
            lightAreaShader.?, "position");
        rl.setShaderValue(
            lightAreaShader.?, positionLocation, 
            &[4]f32{self.dest.x, self.dest.y, self.dest.width, self.dest.height},
            rl.ShaderUniformDataType.vec4);

        const lightPositionLocation = rl.getShaderLocation(
            lightAreaShader.?, "lightPosition");
        rl.setShaderValue(
            lightAreaShader.?, lightPositionLocation, 
            &[4]f32{light.start.x, light.start.y, light.end.x, light.end.y},
            rl.ShaderUniformDataType.vec4);

        const focusLocation = rl.getShaderLocation(
            lightAreaShader.?, "focus");
        rl.setShaderValue(
            lightAreaShader.?, focusLocation,
            &[1]f32{light.focus},
            rl.ShaderUniformDataType.float);

        self.baseTexture.drawPro(
            self.source,
            self.dest,
            rl.Vector2{.x = 0, .y = 0},
            0,
            rl.Color.white
        );

        rl.endShaderMode();
        self.redrawArea.end();
    }
};

///compiles and loads shadow shader, must be called before drawing shadows
pub fn initShadowShader() !void
{
    shadowShader = try rl.loadShader(null, "./shader/shadows.fs");
    lightAreaShader = try rl.loadShader(null, "./shader/lightArea.fs");
    shadowAreaShader = try rl.loadShader(null, "./shader/shadowArea.fs");
}

///unloads shadow shader
pub fn deinitShadowShader() void {
    if (shadowShader) |shader|
    {
        rl.unloadShader(shader);
        shadowShader = null;
    }
    if (lightAreaShader) |shader|
    {
        rl.unloadShader(shader);
        lightAreaShader = null;
    }
    if (shadowAreaShader) |shader|
    {
        rl.unloadShader(shader);
        shadowAreaShader = null;
    }
}

const std = @import("std");
const Io = std.Io;

const rl = @import("raylib");

var shadowShader: ?rl.Shader = null;
var lightAreaShader: ?rl.Shader = null;
var shadowAreaShader: ?rl.Shader = null;

pub const ShadowPane = struct {
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
    dest: rl.Rectangle,
    lights: []LightPane,
    shadows: []ShadowPane,
    redrawArea: rl.RenderTexture,
    offset: rl.Vector2,

    pub fn init(
        texture: rl.Texture,
        dest: rl.Rectangle,
        lights: []LightPane,
        shadows: []ShadowPane,
        offset: rl.Vector2,
    ) !ShadowData
    {
        var retval = ShadowData{
            .dest = dest,
            .baseTexture = texture,
            .lights = lights,
            .shadows = shadows,
            .offset = offset,
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

    pub fn resize(self: *ShadowData, newWidth: f32, newHeight: f32) !void
    {
        self.dest.width = newWidth;
        self.dest.height = newHeight;

        for (self.lights, 0..) |_, i|
        {
            var newCache = try rl.RenderTexture.init(
                @trunc(newWidth),
                @trunc(newHeight)
            );

            newCache.begin();
            rl.clearBackground(rl.Color.black);
            newCache.end();

            self.redrawArea.unload();
            self.redrawArea = try rl.RenderTexture.init(
                @trunc(newWidth),
                @trunc(newHeight)
            );

            self.redrawArea.begin();
            rl.clearBackground(rl.Color.white);
            self.redrawArea.end();

            self.lights[i].cache.unload();
            self.lights[i].cache = newCache;

            self.recalculateLight(i);
        }

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
            &[4]f32{self.dest.x + self.offset.x, self.dest.y + self.offset.y, self.dest.width, self.dest.height},
            rl.ShaderUniformDataType.vec4);

        var shadowDataBuf: [128]f32 = undefined;

        for (0..self.shadows.len) |i|
        {
            shadowDataBuf[i * 8 + 0] = self.shadows[i].start.x;
            shadowDataBuf[i * 8 + 1] = self.shadows[i].start.y;
            shadowDataBuf[i * 8 + 2] = self.shadows[i].end.x;
            shadowDataBuf[i * 8 + 3] = self.shadows[i].end.y;
            shadowDataBuf[i * 8 + 4] = self.shadows[i].color.normalize().x;
            shadowDataBuf[i * 8 + 5] = self.shadows[i].color.normalize().y;
            shadowDataBuf[i * 8 + 6] = self.shadows[i].color.normalize().z;
            shadowDataBuf[i * 8 + 7] = 0;
        }

        const shadowData = rl.Image{
            .data = &shadowDataBuf,
            .mipmaps = 1,
            .format = rl.PixelFormat.uncompressed_r32g32b32a32,
            .height = @intCast(self.shadows.len),
            .width = 2
        };

        const shadowDataTex = shadowData.toTexture() catch @panic("failed to load texture");
        defer shadowDataTex.unload();

        const lightColorLocation = rl.getShaderLocation(
            shadowShader.?, "color");
        const lightPositionLocation = rl.getShaderLocation(
            shadowShader.?, "lightPosition");
        const shadowDataLocation = rl.getShaderLocation(
            shadowShader.?, "shadowData");
        const shadowCountLocation = rl.getShaderLocation(
            shadowShader.?, "shadowCount");

        rl.setShaderValue(
            shadowShader.?,
            shadowCountLocation,
            &.{self.shadows.len},
            rl.ShaderUniformDataType.int
        );

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

        rl.setShaderValueTexture(shadowShader.?, shadowDataLocation, shadowDataTex);
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
            &[4]f32{self.dest.x + self.offset.x, self.dest.y + self.offset.y,
                self.dest.width, self.dest.height},
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
            rl.Rectangle.init(0, 0, 1, 1),
            self.dest,
            rl.Vector2{.x = 0, .y = 0},
            0,
            rl.Color.white
        );

        rl.endShaderMode();
        self.redrawArea.end();
    }

    pub fn drawLights(self: ShadowData) void
    {
        rl.drawRectangleRec(self.dest, rl.Color.black);
        rl.beginBlendMode(rl.BlendMode.additive);
        defer rl.endBlendMode();
        for (0..self.lights.len) |i|
        {
            self.lights[i].cache.texture.drawPro(
                self.dest, self.dest,
                rl.Vector2.init(0, 0),
                0, 
                rl.Color.white);
        }
    }

    pub fn updateOffset(self: *ShadowData, newOffset: rl.Vector2) !void
    {
        const deltaOffset = rl.Vector2.init(
            self.offset.x - newOffset.x,
            self.offset.y - newOffset.y);

        self.offset = newOffset;

        const temp = try rl.RenderTexture.init(
                @trunc(self.dest.width),
                @trunc(self.dest.height));
        defer temp.unload();

        for (self.lights, 0..) |light, i|
        {
            self.redrawArea.begin();
            rl.clearBackground(rl.Color.white);
            rl.drawRectangleRec(
                rl.Rectangle.init(
                    deltaOffset.x + 1,
                    deltaOffset.y + 1,
                    self.dest.width - 2,
                    self.dest.height - 2),
                rl.Color.black);
            self.redrawArea.end();
            temp.begin();
            light.cache.texture.drawV(deltaOffset, rl.Color.white);
            temp.end();
            light.cache.begin();
            temp.texture.draw(0, 0, rl.Color.white);
            light.cache.end();
            self.recalculateLight(i);
        }

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

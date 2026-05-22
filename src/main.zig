const std = @import("std");
const Io = std.Io;

const smoothShadows2D = @import("smoothShadows2D");
const rl = @import("raylib");

pub fn main(init: std.process.Init) !void {
    
    rl.initWindow(750, 750, "Smooth shadows 2d");
    defer rl.closeWindow();

    const baseTexture = try rl.loadTexture("./textures/white.png");
    defer rl.unloadTexture(baseTexture);

    try smoothShadows2D.initShadowShader();
    defer smoothShadows2D.deinitShadowShader();

    var lights = [_]smoothShadows2D.LightPane{
        smoothShadows2D.LightPane.init(1,
            rl.Vector2.init(0, 0), rl.Vector2.init(0, 0),
            rl.Color.init(255, 255, 255, 255)),
        smoothShadows2D.LightPane.init(1,
            rl.Vector2.init(0, 0), rl.Vector2.init(0, 0),
            rl.Color.init(0, 255, 255, 255)),
        smoothShadows2D.LightPane.init(1,
            rl.Vector2.init(0, 0), rl.Vector2.init(0, 0),
            rl.Color.init(255, 0, 255, 255)),
        smoothShadows2D.LightPane.init(1,
            rl.Vector2.init(0, 0), rl.Vector2.init(0, 0),
            rl.Color.init(255, 255, 0, 255))
        };

    var shadows = [_]smoothShadows2D.ShadowPane{
        smoothShadows2D.ShadowPane.init(
            rl.Color.init(155, 255, 55, 255), rl.Vector2.init(100, 400), rl.Vector2.init(200, 350)),
        smoothShadows2D.ShadowPane.init(
            rl.Color.init(155, 255, 55, 255), rl.Vector2.init(200, 350), rl.Vector2.init(200, 200)),
        smoothShadows2D.ShadowPane.init(
            rl.Color.init(155, 255, 55, 255), rl.Vector2.init(200, 200), rl.Vector2.init(100, 400)),

        smoothShadows2D.ShadowPane.init(
            rl.Color.init(255, 55, 155, 255), rl.Vector2.init(400, 200), rl.Vector2.init(500, 250)),
        smoothShadows2D.ShadowPane.init(
            rl.Color.init(255, 55, 155, 255), rl.Vector2.init(500, 250), rl.Vector2.init(600, 100)),
        smoothShadows2D.ShadowPane.init(
            rl.Color.init(255, 55, 155, 255), rl.Vector2.init(600, 100), rl.Vector2.init(400, 200)),

        smoothShadows2D.ShadowPane.init(
            rl.Color.init(55, 155, 255, 255), rl.Vector2.init(400, 550), rl.Vector2.init(550, 500)),
        smoothShadows2D.ShadowPane.init(
            rl.Color.init(55, 155, 255, 255), rl.Vector2.init(550, 500), rl.Vector2.init(500, 350)),
        smoothShadows2D.ShadowPane.init(
            rl.Color.init(55, 155, 255, 255), rl.Vector2.init(500, 350), rl.Vector2.init(400, 550)),

        smoothShadows2D.ShadowPane.init(
            rl.Color.init(0, 0, 0, 255), rl.Vector2.init(360, 360), rl.Vector2.init(360, 385)),
        smoothShadows2D.ShadowPane.init(
            rl.Color.init(0, 0, 0, 255), rl.Vector2.init(360, 385), rl.Vector2.init(385, 385)),
        smoothShadows2D.ShadowPane.init(
            rl.Color.init(0, 0, 0, 255), rl.Vector2.init(385, 385), rl.Vector2.init(385, 360)),
        smoothShadows2D.ShadowPane.init(
            rl.Color.init(0, 0, 0, 255), rl.Vector2.init(385, 360), rl.Vector2.init(360, 360))
    };

    var shadowDrawer = try smoothShadows2D.ShadowData.init(
        baseTexture,
        rl.Rectangle.init(0, 0, 1, 1),
        rl.Rectangle.init(0, 0, 750, 750),
        &lights,
        &shadows
    );
    defer shadowDrawer.deinit();

    //rl.setTargetFPS(10);

    var flipFlop = false;
    var paneNum: usize = 0;
    var hideBoxes = false;

    while (!rl.windowShouldClose())
    {
        rl.beginDrawing();

        if (rl.isMouseButtonPressed(rl.MouseButton.left))
            flipFlop = !flipFlop;

        if (rl.isMouseButtonDown(rl.MouseButton.left))
        {
            if (flipFlop == true)
            {
                shadowDrawer.addLightArea(paneNum);
                lights[paneNum].start = rl.getMousePosition();
                shadowDrawer.addLightArea(paneNum);
                shadowDrawer.recalculateLight(paneNum);
            } else {
                shadowDrawer.addLightArea(paneNum);
                lights[paneNum].end = rl.getMousePosition();
                shadowDrawer.addLightArea(paneNum);
                shadowDrawer.recalculateLight(paneNum);
            }

        }

        if (rl.isKeyDown(rl.KeyboardKey.w))
        {
            shadowDrawer.addLightArea(paneNum);
            lights[paneNum].focus += 0.01;
            if (lights[paneNum].focus > 1) lights[paneNum].focus = 1;
            shadowDrawer.addLightArea(paneNum);
            shadowDrawer.recalculateLight(paneNum);
        }

        if (rl.isKeyDown(rl.KeyboardKey.s))
        {
            shadowDrawer.addLightArea(paneNum);
                lights[paneNum].focus -= 0.01;
            if (lights[paneNum].focus < 0) lights[paneNum].focus = 0;
            shadowDrawer.addLightArea(paneNum);
            shadowDrawer.recalculateLight(paneNum);
        }

        if (rl.isKeyPressed(rl.KeyboardKey.h))
            hideBoxes = !hideBoxes;

        if (rl.isKeyPressed(rl.KeyboardKey.one))paneNum = 0;
        if (rl.isKeyPressed(rl.KeyboardKey.two))paneNum = 1;
        if (rl.isKeyPressed(rl.KeyboardKey.three))paneNum = 2;
        if (rl.isKeyPressed(rl.KeyboardKey.four))paneNum = 3;

        //shadowDrawer.dest.width = @floatFromInt(rl.getScreenWidth());
        //shadowDrawer.dest.height = @floatFromInt(rl.getScreenHeight());
        
        shadowDrawer.drawLights();

        if (!hideBoxes)
        {
            rl.drawRectangleLines(
                @trunc(lights[paneNum].start.x - 10),
                @trunc(lights[paneNum].start.y - 10),
                20, 20, rl.Color.red);

            rl.drawRectangleLines(
                @trunc(lights[paneNum].end.x - 10),
                @trunc(lights[paneNum].end.y - 10),
                20, 20, rl.Color.blue);
        }

        var fpsTextBuffer: [256:0]u8 = undefined;
        _ = try std.fmt.bufPrint(&fpsTextBuffer, "FPS: {}\x00", .{rl.getFPS()});
        rl.drawText(
            &fpsTextBuffer,
            10,
            10,
            10,
            rl.Color.green
        );

        rl.endDrawing();
    }

    _ = init;
}

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

    var light = smoothShadows2D.LightPane.init(
        1.0,
        rl.Vector2.init(100, 100),
        rl.Vector2.init(400, 400),
        rl.Color.init(155, 155, 255, 255)
    );

    var lights = [_]smoothShadows2D.LightPane{light};
    _ = &light;

    var shadowDrawer = try smoothShadows2D.ShadowData.init(
        baseTexture,
        rl.Rectangle.init(0, 0, 1, 1),
        rl.Rectangle.init(0, 0, 750, 750),
        &lights
    );
    defer shadowDrawer.deinit();

    //rl.setTargetFPS(10);

    var flipFlop = false;

    while (!rl.windowShouldClose())
    {
        rl.beginDrawing();

        if (rl.isMouseButtonPressed(rl.MouseButton.left))
        {
            if (flipFlop == true)
            {
                shadowDrawer.addLightArea(0);
                lights[0].start = rl.getMousePosition();
                shadowDrawer.addLightArea(0);
                shadowDrawer.recalculateLight(0);
            } else {
                shadowDrawer.addLightArea(0);
                lights[0].end = rl.getMousePosition();
                shadowDrawer.addLightArea(0);
                shadowDrawer.recalculateLight(0);
            }

            flipFlop = !flipFlop;
        }

        //shadowDrawer.dest.width = @floatFromInt(rl.getScreenWidth());
        //shadowDrawer.dest.height = @floatFromInt(rl.getScreenHeight());
        
        shadowDrawer.lights[0].cache.texture.drawPro(
            rl.Rectangle.init(0, 0, 750, 750),
            rl.Rectangle.init(0, 0, 750, 750),
            rl.Vector2.init(0, 0),
            0, 
            rl.Color.white);

        rl.drawRectangleLines(
            @trunc(lights[0].start.x - 10),
            @trunc(lights[0].start.y - 10),
            20, 20, rl.Color.red);

        rl.drawRectangleLines(
            @trunc(lights[0].end.x - 10),
            @trunc(lights[0].end.y - 10),
            20, 20, rl.Color.blue);

        var fpsTextBuffer: [256:0]u8 = undefined;
        _ = try std.fmt.bufPrint(&fpsTextBuffer, "{}\x00", .{rl.getFPS()});
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

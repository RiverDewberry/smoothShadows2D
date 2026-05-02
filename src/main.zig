const std = @import("std");
const Io = std.Io;

const smoothShadows2D = @import("smoothShadows2D");
const rl = @import("raylib");

pub fn main(init: std.process.Init) !void {
    
    rl.initWindow(500, 500, "Smooth shadows 2d");
    defer rl.closeWindow();

    const baseTexture = try rl.loadTexture("./textures/white.png");
    defer rl.unloadTexture(baseTexture);

    try smoothShadows2D.initShadowShader();
    defer smoothShadows2D.deinitShadowShader();

    var light = smoothShadows2D.LightPane.init(
        0.0,
        rl.Vector2.init(100, 100),
        rl.Vector2.init(400, 400),
        rl.Color.init(155, 155, 255, 255)
    );

    var lights = [_]smoothShadows2D.LightPane{light};
    _ = &light;

    var shadowDrawer = smoothShadows2D.ShadowData.init(
        baseTexture,
        rl.Rectangle.init(0, 0, 1, 1),
        rl.Rectangle.init(0, 0, 500, 500),
        &lights
    );

    //rl.setTargetFPS(30);

    var flipFlop = false;

    while (!rl.windowShouldClose())
    {

        if (rl.isMouseButtonPressed(rl.MouseButton.left))
        {
            if (flipFlop == true)
            {
                lights[0].start = rl.getMousePosition();
            } else {
                lights[0].end = rl.getMousePosition();
            }

            flipFlop = !flipFlop;
        }

        rl.beginDrawing();

        shadowDrawer.dest.width = @floatFromInt(rl.getScreenWidth());
        shadowDrawer.dest.height = @floatFromInt(rl.getScreenHeight());
        shadowDrawer.drawShadows();

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

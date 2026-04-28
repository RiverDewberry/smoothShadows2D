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

    const light = smoothShadows2D.LightPane.init(
        1, rl.Vector2.init(100, 100),
        rl.Vector2.init(400, 400),
        rl.Color.init(255, 255, 255, 255)
    );

    const shadowDrawer = smoothShadows2D.ShadowData.init(
        baseTexture,
        rl.Rectangle.init(0, 0, 1, 1),
        rl.Rectangle.init(0, 0, 500, 500),
        []smoothShadows2D.LightPane{light}
    );

    rl.setTargetFPS(30);

    while (!rl.windowShouldClose())
    {
        rl.beginDrawing();

        shadowDrawer.drawShadows();

        rl.endDrawing();
    }

    _ = init;
}

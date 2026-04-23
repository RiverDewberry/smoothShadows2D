const std = @import("std");
const Io = std.Io;

const smoothShadows2D = @import("smoothShadows2D");
const rl = @import("raylib");

pub fn main(init: std.process.Init) !void {
    
    rl.initWindow(500, 500, "Smooth shadows 2d");
    defer rl.closeWindow();

    const baseTexture = try rl.loadTexture("../textures/white.png");
    defer rl.unloadTexture(baseTexture);

    rl.setTargetFPS(30);

    while (!rl.windowShouldClose())
    {

        rl.beginDrawing();

        baseTexture.drawPro(
            rl.Rectangle.init(0.0, 0.0, 1.0, 1.0),
            rl.Rectangle.init(0.0, 0.0, 500.0, 500.0),
            rl.Vector2.init(0.0, 0.0),
            0,
            rl.Color.white
        );

        rl.endDrawing();
    }

    _ = init;
}

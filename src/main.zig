const std = @import("std");
const Io = std.Io;

const smoothShadows2D = @import("smoothShadows2D");
const rl = @import("raylib");

pub fn main(init: std.process.Init) !void {
    
    rl.initWindow(500, 500, "Smooth shadows 2d");
    defer rl.closeWindow();

    while (!rl.windowShouldClose())
    {

        rl.beginDrawing();

        rl.endDrawing();
    }

    _ = init;
}

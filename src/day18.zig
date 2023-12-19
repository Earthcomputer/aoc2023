const root = @import("root");
const std = @import("std");

const Dir = enum {
    UP, DOWN, LEFT, RIGHT,

    fn from_char(char: u8) ?Dir {
        switch (char) {
            'U' => return Dir.UP,
            'D' => return Dir.DOWN,
            'L' => return Dir.LEFT,
            'R' => return Dir.RIGHT,
            else => return null,
        }
    }
};

const Instruction = struct {
    dir: Dir,
    distance: i64,
    color: u24,
};

fn parseInput() root.AOCError![]Instruction {
    const input = try root.readInput();
    defer root.alloc.free(input);

    var instructions = std.ArrayList(Instruction).init(root.alloc);
    defer instructions.deinit();

    var lines = std.mem.split(u8, input, "\n");
    while (lines.next()) |line| {
        var parts = std.mem.split(u8, line, " ");
        const dirStr = parts.next() orelse continue;
        if (dirStr.len != 1) {
            continue;
        }
        const dir = Dir.from_char(dirStr[0]) orelse continue;
        const distanceStr = parts.next() orelse continue;
        const distance = std.fmt.parseInt(i64, distanceStr, 10) catch continue;
        const colorStr = parts.next() orelse continue;
        if (!std.mem.startsWith(u8, colorStr, "(#")) {
            continue;
        }
        if (!std.mem.endsWith(u8, colorStr, ")")) {
            continue;
        }
        const color = std.fmt.parseInt(u24, colorStr[2..colorStr.len - 1], 16) catch continue;
        try instructions.append(.{
            .dir = dir,
            .distance = distance,
            .color = color,
        });
    }

    return instructions.toOwnedSlice();
}

const Point = struct {
    x: i64, y: i64,
};

pub fn part1() root.AOCError!void {
    const input = try parseInput();
    defer root.alloc.free(input);

    try run(input);
}

pub fn part2() root.AOCError!void {
    var input = try parseInput();
    defer root.alloc.free(input);

    for (input) |*instruction| {
        switch (instruction.color & 15) {
            0 => instruction.dir = Dir.RIGHT,
            1 => instruction.dir = Dir.DOWN,
            2 => instruction.dir = Dir.LEFT,
            3 => instruction.dir = Dir.UP,
            else => {
                try root.println("Invalid input", .{});
                return;
            }
        }
        instruction.distance = instruction.color >> 4;
    }

    try run(input);
}

fn run(input: []const Instruction) root.AOCError!void {
    var points = std.ArrayList(Point).init(root.alloc);
    defer points.deinit();

    var x: i64 = 0;
    var y: i64 = 0;
    var perimeter: u64 = 0;
    for (input) |instruction| {
        switch (instruction.dir) {
            Dir.DOWN => y += instruction.distance,
            Dir.UP => y -= instruction.distance,
            Dir.LEFT => x -= instruction.distance,
            Dir.RIGHT => x += instruction.distance,
        }
        try points.append(.{.x = x, .y = y});
        perimeter += std.math.absCast(instruction.distance);
    }

    var realArea: i64 = 0;
    var i: usize = 0;
    while (i < points.items.len) : (i += 1) {
        realArea += (points.items[i].y + points.items[(i + 1) % points.items.len].y) * (points.items[i].x - points.items[(i + 1) % points.items.len].x);
    }
    realArea = @divTrunc(realArea, 2);

    const interiorArea = std.math.absCast(realArea) - perimeter / 2 + 1;

    const area = perimeter + interiorArea;
    try root.println("{d}", .{area});
}

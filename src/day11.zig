const root = @import("root");
const std = @import("std");

const Point = struct {
    x: u64,
    y: u64,
};

fn parseInput() root.AOCError![]Point {
    const input = try root.readInput();
    defer root.alloc.free(input);
    var result = std.ArrayList(Point).init(root.alloc);
    var lines = std.mem.split(u8, input, "\n");
    var y: u64 = 0;
    while (lines.next()) |line| {
        var x: u64 = 0;
        while (x < line.len) : (x += 1) {
            if (line[x] == '#') {
                try result.append(.{.x = x, .y = y});
            }
        }
        y += 1;
    }
    return result.toOwnedSlice();
}

pub fn part1() root.AOCError!void {
   try run(1);
}

pub fn part2() root.AOCError!void {
    try run(999999);
}

fn run(extra: u64) root.AOCError!void {
    const points = try parseInput();
    defer root.alloc.free(points);

    var maxX: u64 = 0;
    var maxY: u64 = 0;
    for (points) |point| {
        maxX = std.math.max(maxX, point.x);
        maxY = std.math.max(maxY, point.y);
    }

    var ix = maxX + 1;
    while (ix > 0) : (ix -= 1) {
        const x = ix - 1;
        var isColumnEmpty = true;
        for (points) |point| {
            if (point.x == x) {
                isColumnEmpty = false;
                break;
            }
        }
        if (isColumnEmpty) {
            for (points) |*point| {
                if (point.*.x > x) {
                    point.*.x += extra;
                }
            }
        }
    }

    var iy = maxY + 1;
    while (iy > 0) : (iy -= 1) {
        const y = iy - 1;
        var isRowEmpty = true;
        for (points) |point| {
            if (point.y == y) {
                isRowEmpty = false;
                break;
            }
        }
        if (isRowEmpty) {
            for (points) |*point| {
                if (point.*.y > y) {
                    point.*.y += extra;
                }
            }
        }
    }

    var total: u64 = 0;
    var i: u64 = 0;
    while (i < points.len - 1) : (i += 1) {
        var j: u64 = i + 1;
        while (j < points.len) : (j += 1) {
            total += std.math.absCast(@intCast(i64, points[i].x) - @intCast(i64, points[j].x));
            total += std.math.absCast(@intCast(i64, points[i].y) - @intCast(i64, points[j].y));
        }
    }

    try root.println("{d}", .{total});
}

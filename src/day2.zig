const root = @import("root");
const std = @import("std");

const Set = struct {
    red: u32,
    green: u32,
    blue: u32,
};

pub fn part1() root.AOCError!void {
    var games = try parseInput();
    defer {
        for (games.items) |game| {
            game.deinit();
        }
        games.deinit();
    }

    var total: usize = 0;
    var i: usize = 0;
    while (i < games.items.len) : (i += 1) {
        var possible = true;
        for (games.items[i].items) |set| {
            if (set.red > 12 or set.green > 13 or set.blue > 14) {
                possible = false;
                break;
            }
        }
        if (possible) {
            total += i + 1;
        }
    }

    try root.println("{d}", .{total});
}

pub fn part2() root.AOCError!void {
    var games = try parseInput();
    defer {
        for (games.items) |game| {
            game.deinit();
        }
        games.deinit();
    }

    var total: u32 = 0;
    for (games.items) |game| {
        var maxRed: u32 = 0;
        var maxGreen: u32 = 0;
        var maxBlue: u32 = 0;
        for (game.items) |set| {
            maxRed = std.math.max(maxRed, set.red);
            maxGreen = std.math.max(maxGreen, set.green);
            maxBlue = std.math.max(maxBlue, set.blue);
        }
        total += maxRed * maxGreen * maxBlue;
    }

    try root.println("{d}", .{total});
}

fn parseInput() root.AOCError!std.ArrayList(std.ArrayList(Set)) {
    const input = try root.readInput();
    defer root.alloc.free(input);

    var games = std.ArrayList(std.ArrayList(Set)).init(root.alloc);

    var lines = std.mem.split(u8, input, "\n");
    while (lines.next()) |line| {
        const colonIndex = std.mem.indexOf(u8, line, ": ") orelse continue;
        var setsStr = std.mem.split(u8, line[colonIndex + 2..], "; ");
        var sets = std.ArrayList(Set).init(root.alloc);
        while (setsStr.next()) |setStr| {
            var set = Set {
                .red = 0,
                .green = 0,
                .blue = 0,
            };
            var elems = std.mem.split(u8, setStr, ", ");
            while (elems.next()) |elem| {
                var parts = std.mem.split(u8, elem, " ");
                const num = std.fmt.parseInt(u32, parts.next() orelse continue, 10) catch continue;
                const color = parts.next() orelse continue;
                if (std.mem.eql(u8, color, "red")) {
                    set.red += num;
                } else if (std.mem.eql(u8, color, "green")) {
                    set.green += num;
                } else if (std.mem.eql(u8, color, "blue")) {
                    set.blue += num;
                }
            }
            try sets.append(set);
        }
        try games.append(sets);
    }

    return games;
}

const root = @import("root");
const std = @import("std");

pub fn part1() root.AOCError!void {
    const input = try root.readInput();
    defer root.alloc.free(input);

    var total: u32 = 0;

    var lines = std.mem.split(u8, input, "\n");
    while (lines.next()) |line| {
        const numMatching = try getNumMatching(line);
        if (numMatching > 0) {
            total += @as(u32, 1) << @intCast(u5, numMatching - 1);
        }
    }

    try root.println("{d}", .{total});
}

pub fn part2() root.AOCError!void {
    const input = try root.readInput();
    defer root.alloc.free(input);

    var lines = std.ArrayList([]const u8).init(root.alloc);
    defer lines.deinit();

    var linesIter = std.mem.split(u8, input, "\n");
    while (linesIter.next()) |line| {
        if (line.len != 0) {
            try lines.append(line);
        }
    }

    var counts = try root.alloc.alloc(u32, lines.items.len);
    defer root.alloc.free(counts);
    std.mem.set(u32, counts, 1);

    var total: u32 = 0;
    var i: usize = 0;
    while (i < counts.len) : (i += 1) {
        const count = counts[i];
        total += count;

        const numMatching = try getNumMatching(lines.items[i]);
        var k: usize = 1;
        while (k <= numMatching) : (k += 1) {
            if (i + k < counts.len) {
                counts[i + k] += count;
            }
        }
    }

    try root.println("{d}", .{total});
}

fn getNumMatching(line: []const u8) root.AOCError!u32 {
    const colonIndex = std.mem.indexOf(u8, line, ":") orelse return 0;
    const lineAfterColon = line[colonIndex + 1..];
    const pipeIndex = std.mem.indexOf(u8, lineAfterColon, "|") orelse return 0;

    var myNumbers = std.AutoHashMap(u32, void).init(root.alloc);
    defer myNumbers.deinit();

    var myNumbersIter = std.mem.split(u8, lineAfterColon[pipeIndex + 1..], " ");
    while (myNumbersIter.next()) |myNumber| {
        if (myNumber.len != 0) {
            const n = std.fmt.parseInt(u32, myNumber, 10) catch continue;
            try myNumbers.put(n, {});
        }
    }

    var numMatching: u32 = 0;
    var theirNumbersIter = std.mem.split(u8, lineAfterColon[0..pipeIndex], " ");
    while (theirNumbersIter.next()) |theirNumber| {
        if (theirNumber.len != 0) {
            const n = std.fmt.parseInt(u32, theirNumber, 10) catch continue;
            if (myNumbers.contains(n)) {
                numMatching += 1;
            }
        }
    }

    return numMatching;
}

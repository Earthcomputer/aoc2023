const root = @import("root");
const std = @import("std");

fn parseInput() root.AOCError![]const []const i32 {
    const input = try root.readInput();
    defer root.alloc.free(input);

    var lines = std.ArrayList([]const i32).init(root.alloc);
    var linesItr = std.mem.split(u8, input, "\n");
    while (linesItr.next()) |line| {
        if (line.len == 0) {
            continue;
        }
        var nums = std.ArrayList(i32).init(root.alloc);
        var numsIter = std.mem.split(u8, line, " ");
        while (numsIter.next()) |numStr| {
            const n = std.fmt.parseInt(i32, numStr, 10) catch continue;
            try nums.append(n);
        }
        try lines.append(nums.toOwnedSlice());
    }

    return lines.toOwnedSlice();
}

fn freeInput(input: []const []const i32) void {
    for (input) |line| {
        root.alloc.free(line);
    }
    root.alloc.free(input);
}

pub fn part1() root.AOCError!void {
    const input = try parseInput();
    defer freeInput(input);

    var total: i32 = 0;

    for (input) |sequence| {
        total += try predictNext(sequence, false);
    }

    try root.println("{d}", .{total});
}

pub fn part2() root.AOCError!void {
    const input = try parseInput();
    defer freeInput(input);

    var total: i32 = 0;

    for (input) |sequence| {
        total += try predictNext(sequence, true);
    }

    try root.println("{d}", .{total});
}

fn predictNext(sequence: []const i32, predictPrev: bool) root.AOCError!i32 {
    var deltas = std.ArrayList([]const i32).init(root.alloc);
    defer {
        var i: usize = 1;
        while (i < deltas.items.len) : (i += 1) {
            root.alloc.free(deltas.items[i]);
        }
        deltas.deinit();
    }

    try deltas.append(sequence);
    while (!std.mem.allEqual(i32, deltas.items[deltas.items.len - 1], 0) and deltas.items[deltas.items.len - 1].len > 1) {
        const prevDeltas = deltas.items[deltas.items.len - 1];
        const nextDeltas = try root.alloc.alloc(i32, prevDeltas.len - 1);
        var i: usize = 0;
        while (i < nextDeltas.len) : (i += 1) {
            nextDeltas[i] = prevDeltas[i + 1] - prevDeltas[i];
        }
        try deltas.append(nextDeltas);
    }

    var prediction: i32 = 0;
    var i: usize = deltas.items.len;
    while (i > 0) : (i -= 1) {
        if (predictPrev) {
            prediction = deltas.items[i - 1][0] - prediction;
        } else {
            prediction += deltas.items[i - 1][deltas.items[i - 1].len - 1];
        }
    }

    return prediction;
}

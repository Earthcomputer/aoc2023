const root = @import("root");
const std = @import("std");

pub fn part1() root.AOCError!void {
    const input = try root.readInput();
    defer root.alloc.free(input);

    var total: u32 = 0;

    var lines = std.mem.split(u8, input, "\n");
    while (lines.next()) |line| {
        if (line.len == 0) {
            continue;
        }

        var i: usize = 0;
        while (i < line.len) : (i += 1) {
            if (line[i] >= '0' and line[i] <= '9') {
                total += 10 * @intCast(u32, line[i] - '0');
                break;
            }
        }
        i = line.len - 1;
        while (true) : (i -= 1) {
            if (line[i] >= '0' and line[i] <= '9') {
                total += @intCast(u32, line[i] - '0');
                break;
            }
            if (i == 0) {
                break;
            }
        }
    }

    try root.println("{d}", .{total});
}

pub fn part2() root.AOCError!void {
    const input = try root.readInput();
    defer root.alloc.free(input);

    var total: u32 = 0;

    var lines = std.mem.split(u8, input, "\n");
    while (lines.next()) |line| {
        const first = firstDigit(line);
        if (first) |f| total += 10 * @intCast(u32, f);
        const last = lastDigit(line);
        if (last) |l| total += @intCast(u32, l);
    }

    try root.println("{d}", .{total});
}

fn firstDigit(str: []const u8) ?u8 {
    const digitIndexes = [_]usize {
        std.mem.indexOf(u8, str, "one") orelse str.len,
        std.mem.indexOf(u8, str, "two") orelse str.len,
        std.mem.indexOf(u8, str, "three") orelse str.len,
        std.mem.indexOf(u8, str, "four") orelse str.len,
        std.mem.indexOf(u8, str, "five") orelse str.len,
        std.mem.indexOf(u8, str, "six") orelse str.len,
        std.mem.indexOf(u8, str, "seven") orelse str.len,
        std.mem.indexOf(u8, str, "eight") orelse str.len,
        std.mem.indexOf(u8, str, "nine") orelse str.len,
    };
    const first = std.mem.indexOfMin(usize, &digitIndexes);

    var i: usize = 0;
    while (i < str.len) : (i += 1) {
        if (str[i] >= '0' and str[i] <= '9') {
            break;
        }
    }

    if (digitIndexes[first] < i) {
        return @intCast(u8, first) + 1;
    } else if (i == str.len) {
        return null;
    } else {
        return str[i] - '0';
    }
}

fn lastDigit(str: []const u8) ?u8 {
    const digitIndexes = [_]isize {
        lastIndexOfOrM1(str, "one"),
        lastIndexOfOrM1(str, "two"),
        lastIndexOfOrM1(str, "three"),
        lastIndexOfOrM1(str, "four"),
        lastIndexOfOrM1(str, "five"),
        lastIndexOfOrM1(str, "six"),
        lastIndexOfOrM1(str, "seven"),
        lastIndexOfOrM1(str, "eight"),
        lastIndexOfOrM1(str, "nine"),
    };
    const last = std.mem.indexOfMax(isize, &digitIndexes);

    var i: isize = @intCast(isize, str.len) - 1;
    while (i >= 0) : (i -= 1) {
        if (str[@intCast(usize, i)] >= '0' and str[@intCast(usize, i)] <= '9') {
            break;
        }
    }

    if (digitIndexes[last] > i) {
        return @intCast(u8, last) + 1;
    } else if (i == -1) {
        return null;
    } else {
        return str[@intCast(usize, i)] - '0';
    }
}

fn lastIndexOfOrM1(str: []const u8, substr: []const u8) isize {
    const result = std.mem.lastIndexOf(u8, str, substr);
    if (result) |index| {
        return @intCast(isize, index);
    } else {
        return -1;
    }
}

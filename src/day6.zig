const root = @import("root");
const std = @import("std");

const Input = struct {
    times: []const u64,
    distances: []const u64,

    fn parse(isPart2: bool) root.AOCError!?Input {
        const input = try root.readInput();
        defer root.alloc.free(input);

        const realInput = if (isPart2)
            try std.mem.replaceOwned(u8, root.alloc, input, " ", "")
         else
            input;
        defer if (isPart2) {
            root.alloc.free(realInput);
        };

        var inputLines = std.mem.split(u8, realInput, "\n");

        const timeLine = inputLines.next() orelse return null;
        if (!std.mem.startsWith(u8, timeLine, "Time:")) {
            return null;
        }
        var timeLineParts = std.mem.split(u8, timeLine[5..], " ");
        var times = std.ArrayList(u64).init(root.alloc);
        while (timeLineParts.next()) |timeLinePart| {
            const time = std.fmt.parseInt(u64, timeLinePart, 10) catch continue;
            try times.append(time);
        }

        const distanceLine = inputLines.next() orelse return null;
        if (!std.mem.startsWith(u8, distanceLine, "Distance:")) {
            times.deinit();
            return null;
        }
        var distanceLineParts = std.mem.split(u8, distanceLine[9..], " ");
        var distances = std.ArrayList(u64).init(root.alloc);
        while (distanceLineParts.next()) |distanceLinePart| {
            const distance = std.fmt.parseInt(u64, distanceLinePart, 10) catch continue;
            try distances.append(distance);
        }

        if (times.items.len != distances.items.len) {
            times.deinit();
            distances.deinit();
            return null;
        }

        return Input {
            .times = times.toOwnedSlice(),
            .distances = distances.toOwnedSlice(),
        };
    }

    fn deinit(self: Input) void {
        root.alloc.free(self.times);
        root.alloc.free(self.distances);
    }
};

pub fn part1() root.AOCError!void {
    const input = (try Input.parse(false)) orelse {
        try root.println("Invalid input", .{});
        return;
    };
    defer input.deinit();

    var product: u64 = 1;
    var i: usize = 0;
    while (i < input.times.len) : (i += 1) {
        product *= getWinningCount(input.times[i], input.distances[i]);
    }

    try root.println("{d}", .{product});
}

pub fn part2() root.AOCError!void {
    const input = (try Input.parse(true)) orelse {
        try root.println("Invalid input", .{});
        return;
    };
    defer input.deinit();
    if (input.times.len != 1) {
        try root.println("Invalid input", .{});
        return;
    }

    try root.println("{d}", .{getWinningCount(input.times[0], input.distances[0])});
}

fn getWinningCount(totalTime: u64, distanceToBeat: u64) u64 {
    var winningCount: u64 = 0;
    var holdTime: u64 = 0;
    while (holdTime < totalTime) : (holdTime += 1) {
        const distance = (totalTime - holdTime) * holdTime;
        if (distance > distanceToBeat) {
            winningCount += 1;
        }
    }
    return winningCount;
}

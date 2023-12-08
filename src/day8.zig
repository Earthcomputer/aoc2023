const root = @import("root");
const std = @import("std");

const GraphValue = struct {
    left: []const u8,
    right: []const u8,
};

const Input = struct {
    input: []const u8,
    instructions: []const u8,
    graph: std.StringHashMap(GraphValue),

    fn parse() root.AOCError!?Input {
        const input = try root.readInput();
        var lines = std.mem.split(u8, input, "\n");

        const instructions = lines.next() orelse return null;
        if (instructions.len == 0) {
            return null;
        }
        for (instructions) |char| {
            if (char != 'L' and char != 'R') {
                return null;
            }
        }

        _ = lines.next() orelse return null; // skip empty line

        var graph = std.StringHashMap(GraphValue).init(root.alloc);
        while (lines.next()) |line| {
            if (line.len != 16) {
                continue;
            }
            if (!std.mem.eql(u8, line[3..7], " = (")) {
                continue;
            }
            if (!std.mem.eql(u8, line[10..12], ", ")) {
                continue;
            }
            if (line[15] != ')') {
                continue;
            }

            try graph.put(line[0..3], GraphValue {
                .left = line[7..10],
                .right = line[12..15],
            });
        }

        return Input {
            .input = input,
            .instructions = instructions,
            .graph = graph,
        };
    }

    fn deinit(self: *Input) void {
        root.alloc.free(self.input);
        self.graph.deinit();
    }
};

pub fn part1() root.AOCError!void {
    var input = (try Input.parse()) orelse {
        try root.println("Invalid input", .{});
        return;
    };
    defer input.deinit();

    const steps = (try getNumberOfSteps(&input, "AAA", isZZZ)) orelse return;

    try root.println("{d}", .{steps});
}

fn isZZZ(location: []const u8) bool {
    return std.mem.eql(u8, location, "ZZZ");
}

pub fn part2() root.AOCError!void {
    var input = (try Input.parse()) orelse {
        try root.println("Invalid input", .{});
        return;
    };
    defer input.deinit();

    var result: u64 = 1;

    var itr = input.graph.keyIterator();
    while (itr.next()) |location| {
        if (std.mem.endsWith(u8, location.*, "A")) {
            const steps = (try getNumberOfSteps(&input, location.*, endsWithZ)) orelse return;
            result = result * steps / std.math.gcd(result, steps);
        }
    }

    try root.println("{d}", .{result});
}

fn endsWithZ(location: []const u8) bool {
    return std.mem.endsWith(u8, location, "Z");
}

fn getNumberOfSteps(input: *const Input, startingLocation: []const u8, comptime isEndingLocation: fn([]const u8) bool) root.AOCError!?usize {
    var steps: usize = 0;
    var location = startingLocation;

    while (!isEndingLocation(location)) {
        const graphValue = input.graph.get(location) orelse {
            try root.println("No value associated with location {s}", .{location});
            return null;
        };
        if (input.instructions[steps % input.instructions.len] == 'L') {
            location = graphValue.left;
        } else {
            location = graphValue.right;
        }
        steps += 1;
    }

    return steps;
}

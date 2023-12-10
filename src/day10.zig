const root = @import("root");
const std = @import("std");

const Grid = []const []const u8;
const Input = struct {
    input: []const u8,
    grid: Grid,

    fn parse() root.AOCError!Input {
        const input = try root.readInput();
        var grid = std.ArrayList([]const u8).init(root.alloc);
        var lines = std.mem.split(u8, input, "\n");
        while (lines.next()) |line| {
            try grid.append(line);
        }
        return Input {
            .input = input,
            .grid = grid.toOwnedSlice(),
        };
    }

    fn deinit(self: Input) void {
        root.alloc.free(self.input);
        root.alloc.free(self.grid);
    }
};

const Delta = struct {
    dx: i2,
    dy: i2,

    fn addX(self: Delta, x: usize) usize {
        return @intCast(usize, @intCast(isize, x) + @intCast(isize, self.dx));
    }

    fn addY(self: Delta, y: usize) usize {
        return @intCast(usize, @intCast(isize, y) + @intCast(isize, self.dy));
    }

    fn negate(self: Delta) Delta {
        return Delta {
            .dx = -self.dx,
            .dy = -self.dy,
        };
    }
};
const UP = Delta { .dx = 0, .dy = -1 };
const DOWN = Delta { .dx = 0, .dy = 1 };
const LEFT = Delta { .dx = -1, .dy = 0 };
const RIGHT = Delta { .dx = 1, .dy = 0 };
const DELTAS = [_]Delta{ UP, DOWN, LEFT, RIGHT };

const DeltaPair = struct {
    a: Delta,
    b: Delta,

    fn contains(self: DeltaPair, delta: Delta) bool {
        return (self.a.dx == delta.dx and self.a.dy == delta.dy) or (self.b.dx == delta.dx and self.b.dy == delta.dy);
    }

    fn getOtherDelta(self: DeltaPair, delta: Delta) Delta {
        if (self.a.dx == delta.dx and self.a.dy == delta.dy) {
            return self.b;
        } else {
            return self.a;
        }
    }
};
fn make_delta_pairs_by_char() [256]?DeltaPair {
    var delta_pairs_by_char = std.mem.zeroes([256]?DeltaPair);
    delta_pairs_by_char['|'] = .{.a = UP, .b = DOWN};
    delta_pairs_by_char['-'] = .{.a = LEFT, .b = RIGHT};
    delta_pairs_by_char['7'] = .{.a = LEFT, .b = DOWN};
    delta_pairs_by_char['F'] = .{.a = RIGHT, .b = DOWN};
    delta_pairs_by_char['J'] = .{.a = LEFT, .b = UP};
    delta_pairs_by_char['L'] = .{.a = RIGHT, .b = UP};
    return delta_pairs_by_char;
}
const DELTA_PAIRS_BY_CHAR = make_delta_pairs_by_char();

const Point = struct {
    x: usize,
    y: usize,
};

fn boundsCheck(grid: Grid, x: usize, y: usize, delta: Delta) bool {
    if (x == 0 and delta.dx == -1) {
        return false;
    }
    if (y == 0 and delta.dy == -1) {
        return false;
    }
    if (y == grid.len - 1 and delta.dy == 1) {
        return false;
    }
    if (x == grid[y].len - 1 and delta.dx == 1) {
        return false;
    }
    return true;
}

fn incLoopLength(counter: *u32, point: Point) root.AOCError!void {
    _ = point;
    counter.* += 1;
}

pub fn part1() root.AOCError!void {
    const input = try Input.parse();
    defer input.deinit();

    var loopLength: u32 = 0;
    if (!try followLoop(&loopLength, input.grid, incLoopLength)) {
        return;
    }

    try root.println("{d}", .{loopLength / 2});
}

fn addLoopPointToSet(set: *std.AutoHashMap(Point, void), point: Point) root.AOCError!void {
    try set.put(point, {});
}

fn startNeighborCheck(grid: Grid, x: usize, y: usize, loopSet: *const std.AutoHashMap(Point, void), direction: Delta) bool {
    return boundsCheck(grid, x, y, direction)
        and loopSet.contains(.{.x = direction.addX(x), .y = direction.addY(y)})
        and DELTA_PAIRS_BY_CHAR[grid[direction.addY(y)][direction.addX(x)]].?.contains(direction.negate());
}

pub fn part2() root.AOCError!void {
    const input = try Input.parse();
    defer input.deinit();

    var loopSet = std.AutoHashMap(Point, void).init(root.alloc);
    defer loopSet.deinit();
    if (!try followLoop(&loopSet, input.grid, addLoopPointToSet)) {
        return;
    }

    var totalArea: u32 = 0;
    var y: usize = 0;
    while (y < input.grid.len) : (y += 1) {
        var x: usize = 0;
        var isInsideLoop = false;
        while (x < input.grid[y].len) : (x += 1) {
            if (loopSet.contains(.{.x = x, .y = y})) {
                const loopChar = input.grid[y][x];
                if (loopChar == 'S') {
                    const left = startNeighborCheck(input.grid, x, y, &loopSet, LEFT);
                    const right = startNeighborCheck(input.grid, x, y, &loopSet, RIGHT);
                    const up = startNeighborCheck(input.grid, x, y, &loopSet, UP);
                    const down = startNeighborCheck(input.grid, x, y, &loopSet, DOWN);
                    if ((up and down) or (right and up) or (left and up)) {
                        isInsideLoop = !isInsideLoop;
                    }
                } else {
                    if (loopChar == '|' or loopChar == 'L' or loopChar == 'J') {
                        isInsideLoop = !isInsideLoop;
                    }
                }
            } else {
                if (isInsideLoop) {
                    totalArea += 1;
                }
            }
        }
    }

    try root.println("{d}", .{totalArea});
}

fn followLoop(context: anytype, grid: Grid, comptime loopPointConsumer: fn(@TypeOf(context), Point)root.AOCError!void) root.AOCError!bool {
    // find S
    var y: usize = 0;
    var x: usize = undefined;
    var foundS = false;
    outer: while (y < grid.len) : (y += 1) {
        x = 0;
        while (x < grid[y].len) : (x += 1) {
            if (grid[y][x] == 'S') {
                foundS = true;
                break :outer;
            }
        }
    }
    if (!foundS) {
        try root.println("Could not find S", .{});
        return false;
    }

    try loopPointConsumer(context, .{.x = x, .y = y});

    // find loop next to S
    var direction: Delta = undefined;
    var foundLoop = false;
    for (DELTAS) |d| {
        if (boundsCheck(grid, x, y, d)) {
            if (DELTA_PAIRS_BY_CHAR[grid[d.addY(y)][d.addX(x)]]) |pair| {
                if (pair.contains(d.negate())) {
                    x = d.addX(x);
                    y = d.addY(y);
                    direction = d;
                    foundLoop = true;
                    break;
                }
            }
        }
    }
    if (!foundLoop) {
        try root.println("Could not find loop from S", .{});
        return false;
    }

    while (grid[y][x] != 'S') {
        try loopPointConsumer(context, .{.x = x, .y = y});

        const pair = DELTA_PAIRS_BY_CHAR[grid[y][x]] orelse {
            try root.println("Loop ended", .{});
            return false;
        };
        direction = pair.getOtherDelta(direction.negate());
        if (!boundsCheck(grid, x, y, direction)) {
            try root.println("Loop went off the edge of the grid", .{});
            return false;
        }
        x = direction.addX(x);
        y = direction.addY(y);
    }

    return true;
}

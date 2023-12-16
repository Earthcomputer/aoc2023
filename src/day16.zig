const root = @import("root");
const std = @import("std");

const Grid = []const []const u8;

const NORTH: u8 = 1;
const EAST: u8 = 2;
const SOUTH: u8 = 4;
const WEST: u8 = 8;

const Beam = struct {
    x: usize,
    y: usize,
    dir: u8,
};

fn readInput() root.AOCError!?Grid {
    const input = try root.readInput();
    defer root.alloc.free(input);

    var grid = std.ArrayList([]const u8).init(root.alloc);
    var gridFinished = false;
    defer {
        if (!gridFinished) {
            for (grid.items) |row| {
                root.alloc.free(row);
            }
            grid.deinit();
        }
    }

    var lines = std.mem.split(u8, input, "\n");
    while (lines.next()) |line| {
        if (line.len == 0) {
            continue;
        }
        var lineCopy = try root.alloc.alloc(u8, line.len);
        std.mem.copy(u8, lineCopy, line);
        try grid.append(lineCopy);
    }

    if (grid.items.len == 0) {
        return null;
    }
    for (grid.items) |row| {
        if (row.len != grid.items[0].len) {
            return null;
        }
    }

    gridFinished = true;
    return grid.toOwnedSlice();
}

pub fn part1() root.AOCError!void {
    const grid = (try readInput()) orelse {
        try root.println("Invaid input", .{});
        return;
    };
    defer {
        for (grid) |row| {
            root.alloc.free(row);
        }
        root.alloc.free(grid);
    }

    try root.println("{d}", .{try run(grid, 0, 0, EAST)});
}

pub fn part2() root.AOCError!void {
    const grid = (try readInput()) orelse {
        try root.println("Invaid input", .{});
        return;
    };
    defer {
        for (grid) |row| {
            root.alloc.free(row);
        }
        root.alloc.free(grid);
    }

    var max: usize = 0;
    var startY: usize = 0;
    while (startY < grid.len) : (startY += 1) {
        max = std.math.max(max, try run(grid, 0, startY, EAST));
        max = std.math.max(max, try run(grid, grid[0].len - 1, startY, WEST));
    }
    var startX: usize = 0;
    while (startX < grid[0].len) : (startX += 1) {
        max = std.math.max(max, try run(grid, startX, 0, SOUTH));
        max = std.math.max(max, try run(grid, startX, grid.len - 1, NORTH));
    }
    try root.println("{d}", .{max});
}

fn run(grid: Grid, startX: usize, startY: usize, startDir: u8) root.AOCError!usize {
    const beams = try root.alloc.alloc(u8, grid.len * grid[0].len);
    defer root.alloc.free(beams);
    @memset(beams.ptr, 0, beams.len);

    var beamsToProcess = std.SinglyLinkedList(Beam){};
    defer {
        var node = beamsToProcess.first;
        while (node) |n| {
            node = n.next;
            root.alloc.destroy(n);
        }
    }

    beamsToProcess.prepend(try newNode(startX, startY, startDir));

    while (beamsToProcess.popFirst()) |node| {
        defer root.alloc.destroy(node);
        const beam = node.data;
        if ((beams[beam.y * grid[0].len + beam.x] & beam.dir) != 0) {
            continue;
        }
        beams[beam.y * grid[0].len + beam.x] |= beam.dir;
        switch (grid[beam.y][beam.x]) {
            '.' => {
                switch (beam.dir) {
                    NORTH => try north(beam, grid, &beamsToProcess),
                    EAST => try east(beam, grid, &beamsToProcess),
                    SOUTH => try south(beam, grid, &beamsToProcess),
                    WEST => try west(beam, grid, &beamsToProcess),
                    else => {}
                }
            },
            '/' => {
                switch (beam.dir) {
                    NORTH => try east(beam, grid, &beamsToProcess),
                    EAST => try north(beam, grid, &beamsToProcess),
                    SOUTH => try west(beam, grid, &beamsToProcess),
                    WEST => try south(beam, grid, &beamsToProcess),
                    else => {}
                }
            },
            '\\' => {
                switch (beam.dir) {
                    NORTH => try west(beam, grid, &beamsToProcess),
                    EAST => try south(beam, grid, &beamsToProcess),
                    SOUTH => try east(beam, grid, &beamsToProcess),
                    WEST => try north(beam, grid, &beamsToProcess),
                    else => {}
                }
            },
            '-' => {
                switch (beam.dir) {
                    NORTH => {
                        try west(beam, grid, &beamsToProcess);
                        try east(beam, grid, &beamsToProcess);
                    },
                    EAST => try east(beam, grid, &beamsToProcess),
                    SOUTH => {
                        try west(beam, grid, &beamsToProcess);
                        try east(beam, grid, &beamsToProcess);
                    },
                    WEST => try west(beam, grid, &beamsToProcess),
                    else => {}
                }
            },
            '|' => {
                switch (beam.dir) {
                    NORTH => try north(beam, grid, &beamsToProcess),
                    EAST => {
                        try north(beam, grid, &beamsToProcess);
                        try south(beam, grid, &beamsToProcess);
                    },
                    SOUTH => try south(beam, grid, &beamsToProcess),
                    WEST => {
                        try north(beam, grid, &beamsToProcess);
                        try south(beam, grid, &beamsToProcess);
                    },
                    else => {}
                }
            },
            else => {}
        }
    }

    var count: usize = 0;
    for (beams) |beam| {
        if (beam != 0) {
            count += 1;
        }
    }
    return count;
}

fn newNode(x: usize, y: usize, dir: u8) root.AOCError!*std.SinglyLinkedList(Beam).Node {
    var node = try root.alloc.create(std.SinglyLinkedList(Beam).Node);
    node.next = null;
    node.data = Beam { .x = x, .y = y, .dir = dir };
    return node;
}

fn north(beam: Beam, grid: Grid, beamsToProcess: *std.SinglyLinkedList(Beam)) root.AOCError!void {
    _ = grid;
    if (beam.y > 0) {
        beamsToProcess.prepend(try newNode(beam.x, beam.y - 1, NORTH));
    }
}

fn east(beam: Beam, grid: Grid, beamsToProcess: *std.SinglyLinkedList(Beam)) root.AOCError!void {
    if (beam.x < grid[0].len - 1) {
        beamsToProcess.prepend(try newNode(beam.x + 1, beam.y, EAST));
    }
}

fn south(beam: Beam, grid: Grid, beamsToProcess: *std.SinglyLinkedList(Beam)) root.AOCError!void {
    if (beam.y < grid.len - 1) {
        beamsToProcess.prepend(try newNode(beam.x, beam.y + 1, SOUTH));
    }
}

fn west(beam: Beam, grid: Grid, beamsToProcess: *std.SinglyLinkedList(Beam)) root.AOCError!void {
    _ = grid;
    if (beam.x > 0) {
        beamsToProcess.prepend(try newNode(beam.x - 1, beam.y, WEST));
    }
}

const root = @import("root");
const std = @import("std");

const Grid = []const []const u8;

fn readInput() root.AOCError!?[]const Grid {
    const input = try root.readInput();
    defer root.alloc.free(input);

    var grids = std.ArrayList(Grid).init(root.alloc);
    var gridsFinished = false;
    defer {
        if (!gridsFinished) {
            for (grids.items) |grid| {
                for (grid) |line| {
                    root.alloc.free(line);
                }
                root.alloc.free(grid);
            }
            grids.deinit();
        }
    }

    var gridsSplit = std.mem.split(u8, input, "\n\n");
    while (gridsSplit.next()) |gridStr| {
        var grid = std.ArrayList([]const u8).init(root.alloc);
        var gridFinished = false;
        defer {
            if (!gridFinished) {
                for (grid.items) |line| {
                    root.alloc.free(line);
                }
                grid.deinit();
            }
        }

        var lines = std.mem.split(u8, gridStr, "\n");
        while (lines.next()) |line| {
            if (line.len == 0) {
                continue;
            }
            var newLine = try root.alloc.alloc(u8, line.len);
            std.mem.copy(u8, newLine, line);
            try grid.append(newLine);
        }

        if (grid.items.len == 0 or grid.items[0].len == 0) {
            continue;
        }
        for (grid.items) |line| {
            if (line.len != grid.items[0].len) {
                return null;
            }
        }

        gridFinished = true;
        try grids.append(grid.toOwnedSlice());
    }

    gridsFinished = true;
    return grids.toOwnedSlice();
}

pub fn part1() root.AOCError!void {
    try run(0);
}

pub fn part2() root.AOCError!void {
    try run(1);
}

fn run(expectedErrorCount: usize) root.AOCError!void {
    const grids = (try readInput()) orelse {
        try root.println("Invalid input", .{});
        return;
    };
    defer {
        for (grids) |grid| {
            for (grid) |line| {
                root.alloc.free(line);
            }
            root.alloc.free(grid);
        }
        root.alloc.free(grids);
    }

    var total: usize = 0;

    for (grids) |grid| {
        var column: usize = 1;
        while (column < grid[0].len) : (column += 1) {
            var errorCount: usize = 0;
            var dColumn: usize = 0;
            while (dColumn < column and column + dColumn < grid[0].len) : (dColumn += 1) {
                var row: usize = 0;
                while (row < grid.len) : (row += 1) {
                    if (grid[row][column - dColumn - 1] != grid[row][column + dColumn]) {
                        errorCount += 1;
                    }
                }
            }
            if (errorCount == expectedErrorCount) {
                total += column;
            }
        }

        var row: usize = 1;
        while (row < grid.len) : (row += 1) {
            var errorCount: usize = 0;
            var dRow: usize = 0;
            while (dRow < row and row + dRow < grid.len) : (dRow += 1) {
                column = 0;
                while (column < grid[0].len) : (column += 1) {
                    if (grid[row - dRow - 1][column] != grid[row + dRow][column]) {
                        errorCount += 1;
                    }
                }
            }
            if (errorCount == expectedErrorCount) {
                total += 100 * row;
            }
        }
    }

    try root.println("{d}", .{total});
}

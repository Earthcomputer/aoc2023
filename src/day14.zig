const root = @import("root");
const std = @import("std");

const Grid = [][]u8;

fn GridHashMap(comptime V: type) type {
    return std.HashMap(Grid, V, struct {
        pub fn hash(self: @This(), grid: Grid) u64 {
            _ = self;
            var hasher = std.hash.Wyhash.init(0);
            std.hash.autoHashStrat(&hasher, grid, std.hash.Strategy.DeepRecursive);
            return hasher.final();
        }

        pub fn eql(self: @This(), a: Grid, b: Grid) bool {
            _ = self;
            var i: usize = 0;
            while (i < a.len) : (i += 1) {
                if (!std.mem.eql(u8, a[i], b[i])) {
                    return false;
                }
            }
            return true;
        }
    }, 80);
}

fn copyGrid(grid: Grid) root.AOCError!Grid {
    var newGrid = try root.alloc.alloc([]u8, grid.len);
    var i: usize = 0;
    while (i < grid.len) : (i += 1) {
        var newRow = try root.alloc.alloc(u8, grid[i].len);
        std.mem.copy(u8, newRow, grid[i]);
        newGrid[i] = newRow;
    }
    return newGrid;
}

fn deleteGrid(grid: Grid) void {
    for (grid) |row| {
        root.alloc.free(row);
    }
    root.alloc.free(grid);
}

fn readInput() root.AOCError!?Grid {
    const input = try root.readInput();
    defer root.alloc.free(input);

    var grid = std.ArrayList([]u8).init(root.alloc);
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

fn computeLoad(grid: Grid) usize {
    var total: usize = 0;
    var rowNum: usize = 0;
    while (rowNum < grid.len) : (rowNum += 1) {
        var colNum: usize = 0;
        while (colNum < grid[0].len) : (colNum += 1) {
            if (grid[rowNum][colNum] == 'O') {
                total += grid.len - rowNum;
            }
        }
    }
    return total;
}

fn tiltNorth(grid: Grid) void {
    var rowNum: usize = 0;
    while (rowNum < grid.len) : (rowNum += 1) {
        var colNum: usize = 0;
        while (colNum < grid[0].len) : (colNum += 1) {
            if (grid[rowNum][colNum] == 'O') {
                var moveToRow = rowNum;
                while (moveToRow > 0) : (moveToRow -= 1) {
                    if (grid[moveToRow - 1][colNum] != '.') {
                        break;
                    }
                }
                grid[rowNum][colNum] = '.';
                grid[moveToRow][colNum] = 'O';
            }
        }
    }
}

fn tiltSouth(grid: Grid) void {
    var rowNumI = grid.len;
    while (rowNumI > 0) : (rowNumI -= 1) {
        const rowNum = rowNumI - 1;
        var colNum: usize = 0;
        while (colNum < grid[0].len) : (colNum += 1) {
            if (grid[rowNum][colNum] == 'O') {
                var moveToRow = rowNum;
                while (moveToRow < grid.len - 1) : (moveToRow += 1) {
                    if (grid[moveToRow + 1][colNum] != '.') {
                        break;
                    }
                }
                grid[rowNum][colNum] = '.';
                grid[moveToRow][colNum] = 'O';
            }
        }
    }
}

fn tiltWest(grid: Grid) void {
    var colNum: usize = 0;
    while (colNum < grid[0].len) : (colNum += 1) {
        var rowNum: usize = 0;
        while (rowNum < grid.len) : (rowNum += 1) {
            if (grid[rowNum][colNum] == 'O') {
                var moveToCol = colNum;
                while (moveToCol > 0) : (moveToCol -= 1) {
                    if (grid[rowNum][moveToCol - 1] != '.') {
                        break;
                    }
                }
                grid[rowNum][colNum] = '.';
                grid[rowNum][moveToCol] = 'O';
            }
        }
    }
}

fn tiltEast(grid: Grid) void {
    var colNumI = grid[0].len;
    while (colNumI > 0) : (colNumI -= 1) {
        const colNum = colNumI - 1;
        var rowNum: usize = 0;
        while (rowNum < grid.len) : (rowNum += 1) {
            if (grid[rowNum][colNum] == 'O') {
                var moveToCol = colNum;
                while (moveToCol < grid[0].len - 1) : (moveToCol += 1) {
                    if (grid[rowNum][moveToCol + 1] != '.') {
                        break;
                    }
                }
                grid[rowNum][colNum] = '.';
                grid[rowNum][moveToCol] = 'O';
            }
        }
    }
}

pub fn part1() root.AOCError!void {
    const grid = (try readInput()) orelse {
        try root.println("Invalid input", .{});
        return;
    };
    defer deleteGrid(grid);

    tiltNorth(grid);

    try root.println("{d}", .{computeLoad(grid)});
}

pub fn part2() root.AOCError!void {
    const grid = (try readInput()) orelse {
        try root.println("Invalid input", .{});
        return;
    };
    defer deleteGrid(grid);

    var seenGrids = GridHashMap(u32).init(root.alloc);
    defer {
        var keys = seenGrids.keyIterator();
        while (keys.next()) |key| {
            deleteGrid(key.*);
        }
        seenGrids.deinit();
    }

    var i: u32 = 0;
    while (i < 1000000000) : (i += 1) {
        if (seenGrids.get(grid)) |lastSeenIndex| {
            var sameIterAs = (1000000000 - lastSeenIndex) % (i - lastSeenIndex) + lastSeenIndex;

            var itr = seenGrids.iterator();
            while (itr.next()) |entry| {
                if (entry.value_ptr.* == sameIterAs) {
                    try root.println("{d}", .{computeLoad(entry.key_ptr.*)});
                    return;
                }
            }
            try root.println("Didn't encounter the correct grid!", .{});
            break;
        }
        try seenGrids.put(try copyGrid(grid), i);
        tiltNorth(grid);
        tiltWest(grid);
        tiltSouth(grid);
        tiltEast(grid);
    }

    try root.println("{d}", .{computeLoad(grid)});
}

const root = @import("root");
const std = @import("std");

pub fn part1() root.AOCError!void {
    const input = try root.readInput();
    defer root.alloc.free(input);

    var lines = std.ArrayList([]const u8).init(root.alloc);
    defer lines.deinit();

    var linesIter = std.mem.split(u8, input, "\n");
    while (linesIter.next()) |line| {
        try lines.append(line);
    }

    var total: u32 = 0;

    var lineNo: usize = 0;
    while (lineNo < lines.items.len) : (lineNo += 1) {
        const line = lines.items[lineNo];

        var column: usize = 0;
        while (column < line.len) {
            // skip over non-numbers
            if (!std.ascii.isDigit(line[column])) {
                column += 1;
                continue;
            }

            // find the end of the number
            const startColumn = column;
            while (column < line.len and std.ascii.isDigit(line[column])) {
                column += 1;
            }

            if (hasAdjacentSymbol(&lines, lineNo, startColumn, column)) {
                total += std.fmt.parseInt(u32, line[startColumn..column], 10) catch continue;
            }
        }
    }

    try root.println("{d}", .{total});
}

fn hasAdjacentSymbol(lines: *const std.ArrayList([]const u8), lineNo: usize, startColumn: usize, endColumn: usize) bool {
    // check above
    if (lineNo != 0) {
        var col = startColumn -| 1;
        while (col < std.math.min(endColumn + 1, lines.items[lineNo - 1].len)) : (col += 1) {
            if (isSymbol(lines.items[lineNo - 1][col])) {
                return true;
            }
        }
    }

    // check below
    if (lineNo != lines.items.len - 1) {
        var col = startColumn -| 1;
        while (col < std.math.min(endColumn + 1, lines.items[lineNo + 1].len)) : (col += 1) {
            if (isSymbol(lines.items[lineNo + 1][col])) {
                return true;
            }
        }
    }

    // check left
    if (startColumn != 0) {
        if (isSymbol(lines.items[lineNo][startColumn - 1])) {
            return true;
        }
    }

    // check right
    if (endColumn != lines.items[lineNo].len) {
        if (isSymbol(lines.items[lineNo][endColumn])) {
            return true;
        }
    }

    return false;
}

fn isSymbol(char: u8) bool {
    return !std.ascii.isDigit(char) and char != '.' and char != ' ';
}

pub fn part2() root.AOCError!void {
    const input = try root.readInput();
    defer root.alloc.free(input);

    var lines = std.ArrayList([]const u8).init(root.alloc);
    defer lines.deinit();

    var linesIter = std.mem.split(u8, input, "\n");
    while (linesIter.next()) |line| {
        try lines.append(line);
    }

    var total: u32 = 0;

    var lineNo: usize = 0;
    while (lineNo < lines.items.len) : (lineNo += 1) {
        const line = lines.items[lineNo];

        var column: usize = 0;
        while (column < line.len) : (column += 1) {
            if (line[column] == '*') {
                if (getGearRatio(&lines, lineNo, column)) |ratio| {
                    total += ratio;
                }
            }
        }
    }

    try root.println("{d}", .{total});
}

fn getGearRatio(lines: *const std.ArrayList([]const u8), lineNo: usize, column: usize) ?u32 {
    var count: u8 = 0;
    var product: u32 = 1;

    // check above
    if (lineNo != 0) {
        const lineAbove = lines.items[lineNo - 1];
        if (getNumberAt(lineAbove, column)) |n| {
            count += 1;
            product *%= n;
        } else {
            if (column != 0) {
                if (getNumberAt(lineAbove, column - 1)) |n| {
                    count += 1;
                    product *%= n;
                }
            }
            if (getNumberAt(lineAbove, column + 1)) |n| {
                count += 1;
                product *%= n;
            }
        }
    }

    // check below
    if (lineNo != lines.items.len - 1) {
        const lineBelow = lines.items[lineNo + 1];
        if (getNumberAt(lineBelow, column)) |n| {
            count += 1;
            product *%= n;
        } else {
            if (column != 0) {
                if (getNumberAt(lineBelow, column - 1)) |n| {
                    count += 1;
                    product *%= n;
                }
            }
            if (getNumberAt(lineBelow, column + 1)) |n| {
                count += 1;
                product *%= n;
            }
        }
    }

    // check left
    if (column != 0) {
        if (getNumberAt(lines.items[lineNo], column - 1)) |n| {
            count += 1;
            product *%= n;
        }
    }

    // check right
    if (getNumberAt(lines.items[lineNo], column + 1)) |n| {
        count += 1;
        product *%= n;
    }

    return if (count == 2) product else null;
}

fn getNumberAt(str: []const u8, index: usize) ?u32 {
    if (index >= str.len or !std.ascii.isDigit(str[index])) {
        return null;
    }

    var startIndex = index;
    while (startIndex > 0 and std.ascii.isDigit(str[startIndex - 1])) {
        startIndex -= 1;
    }
    var endIndex = index;
    while (endIndex < str.len and std.ascii.isDigit(str[endIndex])) {
        endIndex += 1;
    }

    return std.fmt.parseInt(u32, str[startIndex..endIndex], 10) catch null;
}

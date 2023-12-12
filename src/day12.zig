const root = @import("root");
const std = @import("std");

const InputLine = struct {
    record: []const u8,
    contiguousGroups: []const u64,

    fn parse(line: []const u8) root.AOCError!?InputLine {
        var parts = std.mem.split(u8, line, " ");
        const record = parts.next() orelse return null;
        const numbersStr = parts.next() orelse return null;
        var numbers = std.ArrayList(u64).init(root.alloc);
        var numbersSplit = std.mem.split(u8, numbersStr, ",");
        while (numbersSplit.next()) |numberStr| {
            const number = std.fmt.parseInt(u64, numberStr, 10) catch {
                numbers.deinit();
                return null;
            };
            try numbers.append(number);
        }
        return InputLine {
            .record = record,
            .contiguousGroups = numbers.toOwnedSlice(),
        };
    }

    fn deinit(self: InputLine) void {
        root.alloc.free(self.contiguousGroups);
    }
};

fn InputLineHashMap(comptime value: type) type {
    return std.HashMap(InputLine, value, struct {
        pub fn hash(self: @This(), k: InputLine) u64 {
            _ = self;
            var hasher = std.hash.Wyhash.init(0);
            std.hash.autoHashStrat(&hasher, k, std.hash.Strategy.DeepRecursive);
            return hasher.final();
        }

        pub fn eql(self: @This(), a: InputLine, b: InputLine) bool {
            _ = self;
            return std.mem.eql(u8, a.record, b.record) and std.mem.eql(u64, a.contiguousGroups, b.contiguousGroups);
        }
    }, 80);
}

const Input = struct {
    input: []const u8,
    lines: []const InputLine,

    fn parse() root.AOCError!Input {
        const input = try root.readInput();
        var linesSplit = std.mem.split(u8, input, "\n");
        var lines = std.ArrayList(InputLine).init(root.alloc);
        while (linesSplit.next()) |lineStr| {
            if (try InputLine.parse(lineStr)) |line| {
                try lines.append(line);
            }
        }
        return Input {
            .input = input,
            .lines = lines.toOwnedSlice(),
        };
    }

    fn deinit(self: Input) void {
        root.alloc.free(self.input);
        for (self.lines) |line| {
            line.deinit();
        }
        root.alloc.free(self.lines);
    }
};

pub fn part1() root.AOCError!void {
    const input = try Input.parse();
    defer input.deinit();

    var total: u64 = 0;
    for (input.lines) |line| {
        var cache = InputLineHashMap(u64).init(root.alloc);
        defer cache.deinit();
        total += try getNumCombinations(line.record, line.contiguousGroups, &cache);
    }

    try root.println("{d}", .{total});
}

pub fn part2() root.AOCError!void {
    const input = try Input.parse();
    defer input.deinit();

    var total: u64 = 0;
    for (input.lines) |line| {
        const record = try root.alloc.alloc(u8, line.record.len * 5 + 4);
        defer root.alloc.free(record);
        const contiguousGroups = try root.alloc.alloc(u64, line.contiguousGroups.len * 5);
        defer root.alloc.free(contiguousGroups);
        var i: u64 = 0;
        while (i < 5) : (i += 1) {
            if (i != 0) {
                record[i * (line.record.len + 1) - 1] = '?';
            }
            std.mem.copy(u8, record[i * (line.record.len + 1)..], line.record);
            std.mem.copy(u64, contiguousGroups[i * line.contiguousGroups.len..], line.contiguousGroups);
        }
        var cache = InputLineHashMap(u64).init(root.alloc);
        defer cache.deinit();
        total += try getNumCombinations(record, contiguousGroups, &cache);
    }

    try root.println("{d}", .{total});
}

fn getNumCombinations(record: []const u8, contiguousGroups: []const u64, cache: *InputLineHashMap(u64)) root.AOCError!u64 {
    if (contiguousGroups.len == 0) {
        // check we didn't miss a #
        for (record) |c| {
            if (c == '#') {
                return 0;
            }
        }

        return 1;
    }

    if (cache.get(InputLine { .record = record, .contiguousGroups = contiguousGroups })) |value| {
        return value;
    }

    const firstGroupLen = contiguousGroups[0];
    var total: u64 = 0;
    var i: usize = 0;
    while (i + firstGroupLen <= record.len) : (i += 1) {
        var matches = true;
        var j: usize = 0;
        while (j < firstGroupLen) : (j += 1) {
            if (record[i + j] == '.') {
                matches = false;
                break;
            }
        }
        if (i + firstGroupLen < record.len and record[i + firstGroupLen] == '#') {
            // we would be skipping a # by placing here
            matches = false;
        }
        if (matches) {
            if (i + firstGroupLen == record.len) {
                if (contiguousGroups.len == 1) {
                    total += 1;
                }
            } else {
                total += try getNumCombinations(record[i + firstGroupLen + 1..], contiguousGroups[1..], cache);
            }
        }
        if (record[i] == '#') {
            // we can't skip a #
            break;
        }
    }

    try cache.put(InputLine { .record = record, .contiguousGroups = contiguousGroups }, total);

    return total;
}

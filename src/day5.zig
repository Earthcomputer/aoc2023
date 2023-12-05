const root = @import("root");
const std = @import("std");

const Range = struct {
    start: u64,
    end: u64,
};

const RangeMap = struct {
    target: u64,
    sourceStart: u64,
    sourceLen: u64,

    fn parse(line: []const u8) ?RangeMap {
        var parts = std.mem.split(u8, line, " ");
        const targetStr = parts.next() orelse return null;
        const sourceStartStr = parts.next() orelse return null;
        const sourceLenStr = parts.next() orelse return null;

        const target = std.fmt.parseInt(u64, targetStr, 10) catch return null;
        const sourceStart = std.fmt.parseInt(u64, sourceStartStr, 10) catch return null;
        const sourceLen = std.fmt.parseInt(u64, sourceLenStr, 10) catch return null;

        return RangeMap {
            .target = target,
            .sourceStart = sourceStart,
            .sourceLen = sourceLen,
        };
    }

    fn parseRangeMapList(header: []const u8, lines: *std.mem.SplitIterator(u8)) root.AOCError!?std.ArrayList(RangeMap) {
        if (!std.mem.eql(u8, lines.next() orelse return null, header)) {
            return null;
        }
        var rangeList = std.ArrayList(RangeMap).init(root.alloc);
        while (lines.next()) |line| {
            if (line.len == 0) {
                break;
            }
            if (RangeMap.parse(line)) |range| {
                try rangeList.append(range);
            }
        }
        return rangeList;
    }

    fn map(self: *const RangeMap, n: u64) ?u64 {
        if (n >= self.sourceStart and n < self.sourceStart + self.sourceLen) {
            return n - self.sourceStart + self.target;
        } else {
            return null;
        }
    }

    fn mapRange(self: *const RangeMap, range: Range) struct {
        mappedRange: ?Range,
        leftoverRange1: ?Range,
        leftoverRange2: ?Range,
    } {
        const sourceEnd = self.sourceStart + self.sourceLen;

        // case 1: none of the range gets mapped
        // map:   |----|
        // range:        |----|
        if (sourceEnd <= range.start or self.sourceStart >= range.end) {
            return .{
                .leftoverRange1 = range,
                .mappedRange = null,
                .leftoverRange2 = null,
            };
        }

        // case 2: entire range gets mapped
        // map:   |--------|
        // range:   |****|
        if (self.sourceStart <= range.start and sourceEnd >= range.end) {
            return .{
                .mappedRange = Range {
                    .start = range.start - self.sourceStart + self.target,
                    .end = range.end - self.sourceStart + self.target,
                },
                .leftoverRange1 = null,
                .leftoverRange2 = null,
            };
        }

        // case 3: some of the range gets mapped with leftover on both sides
        // map:     |----|
        // range: |--****--|
        if (self.sourceStart > range.start and sourceEnd < range.end) {
            return .{
                .mappedRange = Range {
                    .start = self.target,
                    .end = self.target + self.sourceLen,
                },
                .leftoverRange1 = Range {
                    .start = range.start,
                    .end = self.sourceStart,
                },
                .leftoverRange2 = Range {
                    .start = sourceEnd,
                    .end = range.end,
                },
            };
        }

        // case 4: some of the range gets mapped with leftover on the left
        // map:      |------|
        // range: |---****|
        if (self.sourceStart > range.start) {
            return .{
                .mappedRange = Range {
                    .start = self.target,
                    .end = range.end - self.sourceStart + self.target,
                },
                .leftoverRange1 = Range {
                    .start = range.start,
                    .end = self.sourceStart,
                },
                .leftoverRange2 = null,
            };
        }

        // case 5: some of the range gets mapped with leftover on the right
        // map:   |------|
        // range:    |***---|
        return .{
            .mappedRange = Range {
                .start = range.start - self.sourceStart + self.target,
                .end = self.target + self.sourceLen,
            },
            .leftoverRange1 = Range {
                .start = sourceEnd,
                .end = range.end,
            },
            .leftoverRange2 = null,
        };
    }
};

const Input = struct {
    seeds: std.ArrayList(u64),
    seedToSoil: std.ArrayList(RangeMap),
    soilToFertilizer: std.ArrayList(RangeMap),
    fertilizerToWater: std.ArrayList(RangeMap),
    waterToLight: std.ArrayList(RangeMap),
    lightToTemperature: std.ArrayList(RangeMap),
    temperatureToHumidity: std.ArrayList(RangeMap),
    humidityToLocation: std.ArrayList(RangeMap),

    fn parse() root.AOCError!?Input {
        const input = try root.readInput();
        defer root.alloc.free(input);

        var lines = std.mem.split(u8, input, "\n");

        const seedsLine = lines.next() orelse return null;
        if (!std.mem.startsWith(u8, seedsLine, "seeds: ")) {
            return null;
        }
        var seedsSplit = std.mem.split(u8, seedsLine[7..], " ");
        var seeds = std.ArrayList(u64).init(root.alloc);
        while (seedsSplit.next()) |seedStr| {
            const seed = std.fmt.parseInt(u64, seedStr, 10) catch return null;
            try seeds.append(seed);
        }

        _ = lines.next() orelse return null; // empty line

        const seedToSoil = (try RangeMap.parseRangeMapList("seed-to-soil map:", &lines)) orelse return null;
        const soilToFertilizer = (try RangeMap.parseRangeMapList("soil-to-fertilizer map:", &lines)) orelse return null;
        const fertilizerToWater = (try RangeMap.parseRangeMapList("fertilizer-to-water map:", &lines)) orelse return null;
        const waterToLight = (try RangeMap.parseRangeMapList("water-to-light map:", &lines)) orelse return null;
        const lightToTemperature = (try RangeMap.parseRangeMapList("light-to-temperature map:", &lines)) orelse return null;
        const temperatureToHumidity = (try RangeMap.parseRangeMapList("temperature-to-humidity map:", &lines)) orelse return null;
        const humidityToLocation = (try RangeMap.parseRangeMapList("humidity-to-location map:", &lines)) orelse return null;

        return Input {
            .seeds = seeds,
            .seedToSoil = seedToSoil,
            .soilToFertilizer = soilToFertilizer,
            .fertilizerToWater = fertilizerToWater,
            .waterToLight = waterToLight,
            .lightToTemperature = lightToTemperature,
            .temperatureToHumidity = temperatureToHumidity,
            .humidityToLocation = humidityToLocation,
        };
    }

    fn deinit(self: Input) void {
        self.seeds.deinit();
        self.seedToSoil.deinit();
        self.soilToFertilizer.deinit();
        self.fertilizerToWater.deinit();
        self.waterToLight.deinit();
        self.lightToTemperature.deinit();
        self.temperatureToHumidity.deinit();
        self.humidityToLocation.deinit();
    }
};

pub fn part1() root.AOCError!void {
    var input = (try Input.parse()) orelse {
        try root.println("Invalid input", .{});
        return;
    };
    defer input.deinit();

    var values = try root.alloc.alloc(u64, input.seeds.items.len);
    defer root.alloc.free(values);
    std.mem.copy(u64, values, input.seeds.items);

    applyMap(values, &input.seedToSoil);
    applyMap(values, &input.soilToFertilizer);
    applyMap(values, &input.fertilizerToWater);
    applyMap(values, &input.waterToLight);
    applyMap(values, &input.lightToTemperature);
    applyMap(values, &input.temperatureToHumidity);
    applyMap(values, &input.humidityToLocation);

    const minLocation = std.mem.min(u64, values);
    try root.println("{d}", .{minLocation});
}

fn applyMap(values: []u64, map: *const std.ArrayList(RangeMap)) void {
    for (values) |*value| {
        for (map.items) |range| {
            if (range.map(value.*)) |newValue| {
                value.* = newValue;
                break;
            }
        }
    }
}

pub fn part2() root.AOCError!void {
    var input = (try Input.parse()) orelse {
        try root.println("Invalid input", .{});
        return;
    };
    defer input.deinit();

    var ranges = try std.ArrayList(Range).initCapacity(root.alloc, input.seeds.items.len / 2);
    var i: usize = 0;
    while (i + 1 < input.seeds.items.len) : (i += 2) {
        try ranges.append(Range {
            .start = input.seeds.items[i],
            .end = input.seeds.items[i] + input.seeds.items[i + 1],
        });
    }

    ranges = try applyMapOnRanges(ranges, &input.seedToSoil);
    ranges = try applyMapOnRanges(ranges, &input.soilToFertilizer);
    ranges = try applyMapOnRanges(ranges, &input.fertilizerToWater);
    ranges = try applyMapOnRanges(ranges, &input.waterToLight);
    ranges = try applyMapOnRanges(ranges, &input.lightToTemperature);
    ranges = try applyMapOnRanges(ranges, &input.temperatureToHumidity);
    ranges = try applyMapOnRanges(ranges, &input.humidityToLocation);

    var min: u64 = std.math.maxInt(u64);
    for (ranges.items) |range| {
        min = std.math.min(min, range.start);
    }

    try root.println("{d}", .{min});
}

fn applyMapOnRanges(rangesIn: std.ArrayList(Range), map: *const std.ArrayList(RangeMap)) root.AOCError!std.ArrayList(Range) {
    var ranges = rangesIn;
    var result = std.ArrayList(Range).init(root.alloc);
    for (map.items) |rangeMap| {
        var leftoverRanges = std.ArrayList(Range).init(root.alloc);
        for (ranges.items) |range| {
            const mapped = rangeMap.mapRange(range);
            if (mapped.mappedRange) |mappedRange| {
                try result.append(mappedRange);
            }
            if (mapped.leftoverRange1) |leftover| {
                try leftoverRanges.append(leftover);
            }
            if (mapped.leftoverRange2) |leftover| {
                try leftoverRanges.append(leftover);
            }
        }
        ranges.deinit();
        ranges = leftoverRanges;
    }

    try result.appendSlice(ranges.items);
    ranges.deinit();

    return result;
}

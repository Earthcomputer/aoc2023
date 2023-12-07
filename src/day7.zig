const root = @import("root");
const std = @import("std");

const HandType = enum(u8) {
    HIGH_CARD,
    ONE_PAIR,
    TWO_PAIRS,
    THREE_OF_A_KIND,
    FULL_HOUSE,
    FOUR_OF_A_KIND,
    FIVE_OF_A_KIND,
};

const Hand = struct {
    hand: [5]u8,
    bid: u32,

    fn parse(line: []const u8) ?Hand {
        if (line.len < 7) {
            return null;
        }
        if (line[5] != ' ') {
            return null;
        }
        const bid = std.fmt.parseInt(u32, line[6..], 10) catch return null;
        return Hand {
            .hand = line[0..5].*,
            .bid = bid,
        };
    }

    fn lessThan1(_context: void, self: Hand, other: Hand) bool {
        _ = _context;
        return self.lessThan(other, false);
    }

    fn lessThan2(_context: void, self: Hand, other: Hand) bool {
        _ = _context;
        return self.lessThan(other, true);
    }

    fn lessThan(self: Hand, other: Hand, isPart2: bool) bool {
        const selfHandType = self.getHandType(isPart2);
        const otherHandType = other.getHandType(isPart2);
        if (selfHandType != otherHandType) {
            return @enumToInt(selfHandType) < @enumToInt(otherHandType);
        }

        var i: usize = 0;
        while (i < 5) : (i += 1) {
            if (self.hand[i] != other.hand[i]) {
                if (isPart2) {
                    if (self.hand[i] == 'J') {
                        return true;
                    }
                    if (other.hand[i] == 'J') {
                        return false;
                    }
                }
                return (charIndex(self.hand[i]) orelse 13) < (charIndex(other.hand[i]) orelse 13);
            }
        }

        return false;
    }

    fn getHandType(self: Hand, isPart2: bool) HandType {
        var counts = std.mem.zeroes([13]u8);
        for (self.hand) |card| {
            if (charIndex(card)) |i| {
                counts[i] += 1;
            }
        }

        if (isPart2) {
            const jokerCount = counts[9];
            counts[9] = 0;
            if (jokerCount > 0) {
                counts[std.mem.indexOfMax(u8, &counts)] += jokerCount;
            }
        }

        var countCounts = std.mem.zeroes([6]u8);
        for (counts) |count| {
            countCounts[@intCast(usize, count)] += 1;
        }

        if (countCounts[5] == 1) {
            return HandType.FIVE_OF_A_KIND;
        }
        if (countCounts[4] == 1) {
            return HandType.FOUR_OF_A_KIND;
        }
        if (countCounts[3] == 1 and countCounts[2] == 1) {
            return HandType.FULL_HOUSE;
        }
        if (countCounts[3] == 1) {
            return HandType.THREE_OF_A_KIND;
        }
        if (countCounts[2] == 2) {
            return HandType.TWO_PAIRS;
        }
        if (countCounts[2] == 1) {
            return HandType.ONE_PAIR;
        }
        return HandType.HIGH_CARD;
    }
};

fn parseInput() root.AOCError!std.ArrayList(Hand) {
    const input = try root.readInput();
    defer root.alloc.free(input);

    var result = std.ArrayList(Hand).init(root.alloc);
    var inputLines = std.mem.split(u8, input, "\n");
    while (inputLines.next()) |inputLine| {
        const hand = Hand.parse(inputLine) orelse continue;
        try result.append(hand);
    }

    return result;
}

fn charIndex(char: u8) ?usize {
    switch (char) {
        'A' => return 12,
        'K' => return 11,
        'Q' => return 10,
        'J' => return 9,
        'T' => return 8,
        '2'...'9' => return @intCast(usize, char - '2'),
        else => return null,
    }
}

pub fn part1() root.AOCError!void {
    try run(false);
}

pub fn part2() root.AOCError!void {
    try run(true);
}

fn run(comptime isPart2: bool) root.AOCError!void {
    var input = try parseInput();
    defer input.deinit();

    std.sort.sort(Hand, input.items, {}, if (isPart2) Hand.lessThan2 else Hand.lessThan1);

    var total: u32 = 0;
    var i: usize = 0;
    while (i < input.items.len) : (i += 1) {
        total += input.items[i].bid * @intCast(u32, i + 1);
    }

    try root.println("{d}", .{total});
}

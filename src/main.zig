const std = @import("std");

pub const Allocator = std.heap.GeneralPurposeAllocator(.{});
var allocInstance = Allocator{};
pub const alloc = allocInstance.allocator();
pub const AOCError = std.fs.File.OpenError || std.fs.File.Reader.Error || std.fs.File.Writer.Error || Allocator.Error;

const Day = struct {
    part1: *const fn() AOCError!void,
    part2: *const fn() AOCError!void,

    fn create(comptime day: anytype) Day {
        return .{
            .part1 = day.part1,
            .part2 = day.part2,
        };
    }
};

const days = [_]Day {
    Day.create(@import("day1.zig")),
    Day.create(@import("day2.zig")),
    Day.create(@import("day3.zig")),
    Day.create(@import("day4.zig")),
    Day.create(@import("day5.zig")),
};

pub fn main() !void {
    const day = (try askForNumber("Enter the day: ")) orelse return;
    if (day == 0 or day > days.len) {
        try println("{d} is outside the range 1-{d}", .{day, days.len});
        return;
    }

    const part = (try askForNumber("Enter the part: ")) orelse return;
    switch (part) {
        1 => try days[day - 1].part1(),
        2 => try days[day - 1].part2(),
        else => try println("{d} is not 1 or 2", .{part}),
    }
}

fn askForNumber(comptime prompt: []const u8) !?u8 {
    const stdin = std.io.getStdIn().reader();
    const stdout = std.io.getStdOut().writer();

    try stdout.print(prompt, .{});

    const input = (try stdin.readUntilDelimiterOrEofAlloc(alloc, '\n', std.math.maxInt(usize))).?;
    defer alloc.free(input);

    return std.fmt.parseInt(u8, input, 10) catch {
        try stdout.print("Invalid number\n", .{});
        return null;
    };
}

pub fn println(comptime fmt: []const u8, args: anytype) !void {
    return std.io.getStdOut().writer().print(std.fmt.comptimePrint("{s}\n", .{fmt}), args);
}

pub fn readInput() ![]const u8 {
    const file = try std.fs.cwd().openFile("input.txt", .{});
    defer file.close();
    return file.readToEndAlloc(alloc, std.math.maxInt(usize));
}

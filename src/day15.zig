const root = @import("root");
const std = @import("std");

const Entry = struct {
    key: []const u8,
    value: u8,
};

fn hash(str: []const u8) u8 {
    var h: u8 = 0;
    for (str) |c| {
        h +%= c;
        h *%= 17;
    }
    return h;
}

pub fn part1() root.AOCError!void {
    const input = try root.readInput();
    defer root.alloc.free(input);

    var total: u32 = 0;
    var parts = std.mem.split(u8, input, ",");
    while (parts.next()) |part| {
        const h = hash(std.mem.trimRight(u8, part, "\n"));
        total += @intCast(u32, h);
    }

    try root.println("{d}", .{total});
}

pub fn part2() root.AOCError!void {
    const input = try root.readInput();
    defer root.alloc.free(input);

    var hashmap: [256]std.ArrayList(Entry) = undefined;
    for (hashmap) |*box| {
        box.* = std.ArrayList(Entry).init(root.alloc);
    }
    defer {
        for (hashmap) |box| {
            box.deinit();
        }
    }

    var parts = std.mem.split(u8, input, ",");
    while (parts.next()) |partTmp| {
        const part = std.mem.trimRight(u8, partTmp, "\n");
        if (std.mem.endsWith(u8, part, "-")) {
            const label = part[0..part.len - 1];
            const h = hash(label);
            var i: usize = 0;
            while (i < hashmap[h].items.len) : (i += 1) {
                if (std.mem.eql(u8, label, hashmap[h].items[i].key)) {
                    _ = hashmap[h].orderedRemove(i);
                    break;
                }
            }
        } else {
            var entryParts = std.mem.split(u8, part, "=");
            const label = entryParts.next() orelse {
                try root.println("Invalid input", .{});
                return;
            };
            const focalLengthStr = entryParts.next() orelse {
                try root.println("Invalid input", .{});
                return;
            };
            const focalLength = std.fmt.parseInt(u8, focalLengthStr, 10) catch {
                try root.println("Invalid input", .{});
                return;
            };

            const h = hash(label);
            var i: usize = 0;
            var found = false;
            while (i < hashmap[h].items.len) : (i += 1) {
                if (std.mem.eql(u8, label, hashmap[h].items[i].key)) {
                    hashmap[h].items[i].value = focalLength;
                    found = true;
                    break;
                }
            }
            if (!found) {
                try hashmap[h].append(Entry {
                    .key = label,
                    .value = focalLength,
                });
            }
        }
    }

    var total: usize = 0;
    var boxNum: usize = 0;
    while (boxNum < hashmap.len) : (boxNum += 1) {
        var i: usize = 0;
        while (i < hashmap[boxNum].items.len) : (i += 1) {
            total += (boxNum + 1) * (i + 1) * @intCast(usize, hashmap[boxNum].items[i].value);
        }
    }

    try root.println("{d}", .{total});
}

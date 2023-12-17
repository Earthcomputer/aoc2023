const root = @import("root");
const std = @import("std");

const Node = struct {
    h: u32,
    v: u32,
};
const HUGE_NODE = Node {
    .h = std.math.maxInt(u32),
    .v = std.math.maxInt(u32),
};

const QueueEntry = struct {
    index: usize,
    cmp: u32,

    fn from(graph: []const Node, index: usize) QueueEntry {
        return QueueEntry {
            .index = index,
            .cmp = std.math.min(graph[index].h, graph[index].v),
        };
    }

    fn isValid(self: QueueEntry, graph: []const Node) bool {
        return self.cmp == std.math.min(graph[self.index].h, graph[self.index].v);
    }

    fn compare(context: void, a: QueueEntry, b: QueueEntry) std.math.Order {
        _ = context;
        return std.math.order(a.cmp, b.cmp);
    }
};

const Input = struct {
    width: usize,
    grid: []const u8,

    fn parse() root.AOCError!?Input {
        const input = try root.readInput();
        defer root.alloc.free(input);

        var grid = std.ArrayList(u8).init(root.alloc);
        defer grid.deinit();

        var lines = std.mem.split(u8, input, "\n");
        const firstLine = lines.next() orelse return null;
        try grid.appendSlice(firstLine);
        while (lines.next()) |line| {
            if (line.len == 0) {
                continue;
            }
            if (line.len != firstLine.len) {
                return null;
            }
            try grid.appendSlice(line);
        }

        if (grid.items.len == 0) {
            return null;
        }

        for (grid.items) |*cell| {
            cell.* -= '0';
        }

        return Input {
            .width = firstLine.len,
            .grid = grid.toOwnedSlice(),
        };
    }
};

pub fn part1() root.AOCError!void {
    try run(1, 3);
}

pub fn part2() root.AOCError!void {
    try run(4, 10);
}

fn run(minDistance: usize, maxDistance: usize) root.AOCError!void {
    const input = (try Input.parse()) orelse {
        try root.println("Invalid input", .{});
        return;
    };
    defer root.alloc.free(input.grid);

    var graph = try root.alloc.alloc(Node, input.grid.len);
    defer root.alloc.free(graph);
    std.mem.set(Node, graph, HUGE_NODE);
    graph[0].h = 0;
    graph[0].v = 0;

    var queue = std.PriorityQueue(QueueEntry, void, QueueEntry.compare).init(root.alloc, {});
    defer queue.deinit();
    try queue.add(QueueEntry.from(graph, 0));
    while (queue.removeOrNull()) |entry| {
        if (!entry.isValid(graph)) {
            continue;
        }
        const x = entry.index % input.width;
        const y = entry.index / input.width;

        if (graph[entry.index].v != std.math.maxInt(u32)) {
            var dx: usize = 1;
            var dist = graph[entry.index].v;
            while (x + dx < input.width and dx <= maxDistance) : (dx += 1) {
                const i = y * input.width + x + dx;
                dist += input.grid[i];
                if (dx >= minDistance and dist < graph[i].h) {
                    graph[i].h = dist;
                    try queue.add(QueueEntry.from(graph, i));
                }
            }

            dx = 1;
            dist = graph[entry.index].v;
            while (dx <= x and dx <= maxDistance) : (dx += 1) {
                const i = y * input.width + x - dx;
                dist += input.grid[i];
                if (dx >= minDistance and dist < graph[i].h) {
                    graph[i].h = dist;
                    try queue.add(QueueEntry.from(graph, i));
                }
            }
        }

        if (graph[entry.index].h != std.math.maxInt(u32)) {
            var dy: usize = 1;
            var dist = graph[entry.index].h;
            while ((y + dy) * input.width < input.grid.len and dy <= maxDistance) : (dy += 1) {
                const i = (y + dy) * input.width + x;
                dist += input.grid[i];
                if (dy >= minDistance and dist < graph[i].v) {
                    graph[i].v = dist;
                    try queue.add(QueueEntry.from(graph, i));
                }
            }

            dy = 1;
            dist = graph[entry.index].h;
            while (dy <= y and dy <= maxDistance) : (dy += 1) {
                const i = (y - dy) * input.width + x;
                dist += input.grid[i];
                if (dy >= minDistance and dist < graph[i].v) {
                    graph[i].v = dist;
                    try queue.add(QueueEntry.from(graph, i));
                }
            }
        }
    }

    try root.println("{d}", .{std.math.min(graph[graph.len - 1].h, graph[graph.len - 1].v)});
}

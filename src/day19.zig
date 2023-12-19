const root = @import("root");
const std = @import("std");

const Variable = enum(usize) {
    X, M, A, S,

    fn fromChar(char: u8) ?Variable {
        switch (char) {
            'x' => return Variable.X,
            'm' => return Variable.M,
            'a' => return Variable.A,
            's' => return Variable.S,
            else => return null,
        }
    }
};

const Operation = enum {
    LT, GT,

    fn fromChar(char: u8) ?Operation {
        switch (char) {
            '<' => return Operation.LT,
            '>' => return Operation.GT,
            else => return null,
        }
    }
};

const Condition = struct {
    variable: Variable,
    operation: Operation,
    value: u32,

    fn parse(str: []const u8) ?Condition {
        if (str.len < 3) {
            return null;
        }
        const variable = Variable.fromChar(str[0]) orelse return null;
        const operation = Operation.fromChar(str[1]) orelse return null;
        const value = std.fmt.parseInt(u32, str[2..], 10) catch return null;
        return .{
            .variable = variable,
            .operation = operation,
            .value = value,
        };
    }

    fn apply(self: Condition, part: Part) bool {
        const partValue = part.get(self.variable);
        switch (self.operation) {
            Operation.LT => return partValue < self.value,
            Operation.GT => return partValue > self.value,
        }
    }
};

const Rule = struct {
    condition: ?Condition,
    nextRule: []const u8,

    fn parse(str: []const u8) ?Rule {
        if (std.mem.indexOf(u8, str, ":")) |colonIndex| {
            return .{
                .condition = Condition.parse(str[0..colonIndex]) orelse return null,
                .nextRule = str[colonIndex + 1..],
            };
        } else {
            return .{
                .condition = null,
                .nextRule = str,
            };
        }
    }
};

const Part = struct {
    variables: [4]u32,

    fn get(self: Part, variable: Variable) u32 {
        return self.variables[@enumToInt(variable)];
    }

    fn set(self: *Part, variable: Variable, value: u32) void {
        self.variables[@enumToInt(variable)] = value;
    }

    fn parse(str: []const u8) ?Part {
        if (!std.mem.startsWith(u8, str, "{") or !std.mem.endsWith(u8, str, "}")) {
            return null;
        }
        var part = Part { .variables = std.mem.zeroes([4]u32) };
        var assignments = std.mem.split(u8, str[1..str.len - 1], ",");
        while (assignments.next()) |assignment| {
            var kv = std.mem.split(u8, assignment, "=");
            const variableStr = kv.next() orelse return null;
            if (variableStr.len != 1) {
                return null;
            }
            const variable = Variable.fromChar(variableStr[0]) orelse return null;
            const valueStr = kv.next() orelse return null;
            const value = std.fmt.parseInt(u32, valueStr, 10) catch return null;
            part.set(variable, value);
        }
        return part;
    }
};

const Input = struct {
    input: []const u8,
    rules: std.StringHashMap([]const Rule),
    parts: []const Part,

    fn parse() root.AOCError!?Input {
        const input = try root.readInput();
        var rules = std.StringHashMap([]const Rule).init(root.alloc);
        var parts = std.ArrayList(Part).init(root.alloc);
        var finishedParsing = false;
        defer {
            if (!finishedParsing) {
                parts.deinit();
                var rulesItr = rules.valueIterator();
                while (rulesItr.next()) |terms| {
                    root.alloc.free(terms.*);
                }
                rules.deinit();
                root.alloc.free(input);
            }
        }

        var rulesParts = std.mem.split(u8, input, "\n\n");
        const rulesStr = rulesParts.next() orelse return null;
        const partsStr = rulesParts.next() orelse return null;

        var rulesSplit = std.mem.split(u8, rulesStr, "\n");
        while (rulesSplit.next()) |ruleStr| {
            if (ruleStr.len == 0) {
                continue;
            }

            const braceIndex = std.mem.indexOf(u8, ruleStr, "{") orelse return null;
            if (!std.mem.endsWith(u8, ruleStr, "}")) {
                return null;
            }
            const ruleName = ruleStr[0..braceIndex];

            var terms = std.ArrayList(Rule).init(root.alloc);
            defer terms.deinit();

            var termsSplit = std.mem.split(u8, ruleStr[braceIndex + 1..ruleStr.len - 1], ",");
            while (termsSplit.next()) |termStr| {
                try terms.append(Rule.parse(termStr) orelse return null);
            }

            try rules.put(ruleName, terms.toOwnedSlice());
        }

        var partsSplit = std.mem.split(u8, partsStr, "\n");
        while (partsSplit.next()) |partStr| {
            if (partStr.len == 0) {
                continue;
            }
            try parts.append(Part.parse(partStr) orelse return null);
        }

        finishedParsing = true;
        return .{
            .input = input,
            .rules = rules,
            .parts = parts.toOwnedSlice(),
        };
    }

    fn deinit(self: *Input) void {
        root.alloc.free(self.parts);
        var rulesItr = self.rules.valueIterator();
        while (rulesItr.next()) |terms| {
            root.alloc.free(terms.*);
        }
        self.rules.deinit();
        root.alloc.free(self.input);
    }
};

pub fn part1() root.AOCError!void {
    var input = (try Input.parse()) orelse {
        try root.println("Invalid input", .{});
        return;
    };
    defer input.deinit();

    var total: u32 = 0;
    for (input.parts) |part| {
        var ruleName: []const u8 = "in";
        ruleLoop: while (!std.mem.eql(u8, ruleName, "A") and !std.mem.eql(u8, ruleName, "R")) {
            const rule = input.rules.get(ruleName) orelse {
                try root.println("Could not find rule {s}", .{ruleName});
                return;
            };
            for (rule) |term| {
                if (term.condition) |condition| {
                    if (condition.apply(part)) {
                        ruleName = term.nextRule;
                        continue :ruleLoop;
                    }
                } else {
                    ruleName = term.nextRule;
                    continue :ruleLoop;
                }
            }
        }

        if (std.mem.eql(u8, ruleName, "A")) {
            for (part.variables) |value| {
                total += value;
            }
        }
    }

    try root.println("{d}", .{total});
}

const State = struct {
    ruleName: []const u8,
    termIndex: usize,
    mins: Part,
    maxs: Part,

    fn count(self: State) u64 {
        var product: u64 = 1;
        var i: usize = 0;
        while (i < 4) : (i += 1) {
            product *= self.maxs.variables[i] - self.mins.variables[i] + 1;
        }
        return product;
    }
};

pub fn part2() root.AOCError!void {
    var input = (try Input.parse()) orelse {
        try root.println("Invalid input", .{});
        return;
    };
    defer input.deinit();

    var states = std.ArrayList(State).init(root.alloc);
    defer states.deinit();

    try states.append(.{
        .ruleName = "in",
        .termIndex = 0,
        .mins = .{ .variables = [_]u32{1, 1, 1, 1} },
        .maxs = .{ .variables = [_]u32{4000, 4000, 4000, 4000} },
    });

    var total: u64 = 0;

    while (states.popOrNull()) |state| {
        if (std.mem.eql(u8, state.ruleName, "R")) {
            continue;
        }
        if (std.mem.eql(u8, state.ruleName, "A")) {
            total += state.count();
            continue;
        }

        const terms = input.rules.get(state.ruleName) orelse {
            try root.println("Could not find rule {s}", .{state.ruleName});
            return;
        };
        if (state.termIndex >= terms.len) {
            continue;
        }
        if (terms[state.termIndex].condition) |condition| {
            const min = state.mins.get(condition.variable);
            const max = state.maxs.get(condition.variable);
            switch (condition.operation) {
                Operation.LT => {
                    if (min < condition.value) {
                        var newMaxs = state.maxs;
                        newMaxs.set(condition.variable, std.math.min(max, condition.value - 1));
                        try states.append(.{
                            .ruleName = terms[state.termIndex].nextRule,
                            .termIndex = 0,
                            .mins = state.mins,
                            .maxs = newMaxs,
                        });
                    }
                    if (max >= condition.value) {
                        var newMins = state.mins;
                        newMins.set(condition.variable, std.math.max(min, condition.value));
                        try states.append(.{
                            .ruleName = state.ruleName,
                            .termIndex = state.termIndex + 1,
                            .mins = newMins,
                            .maxs = state.maxs,
                        });
                    }
                },
                Operation.GT => {
                    if (max > condition.value) {
                        var newMins = state.mins;
                        newMins.set(condition.variable, std.math.max(min, condition.value + 1));
                        try states.append(.{
                            .ruleName = terms[state.termIndex].nextRule,
                            .termIndex = 0,
                            .mins = newMins,
                            .maxs = state.maxs,
                        });
                    }
                    if (min <= condition.value) {
                        var newMaxs = state.maxs;
                        newMaxs.set(condition.variable, std.math.min(max, condition.value));
                        try states.append(.{
                            .ruleName = state.ruleName,
                            .termIndex = state.termIndex + 1,
                            .mins = state.mins,
                            .maxs = newMaxs,
                        });
                    }
                }
            }
        } else {
            try states.append(.{
                .ruleName = terms[state.termIndex].nextRule,
                .termIndex = 0,
                .mins = state.mins,
                .maxs = state.maxs,
            });
        }
    }

    try root.println("{d}", .{total});
}

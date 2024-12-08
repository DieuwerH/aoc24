const std = @import("std");
const dbg = std.debug;
const ArrayList = std.ArrayList;
const print = dbg.print;

pub fn main() !void {
    print("Hello Day 6\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        _ = gpa.deinit();
    }

    // open file
    const path = "input_day6_example.txt";
    // const path = "input_day6.txt";
    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    // // read the file into a buffer
    const stat = try file.stat();
    const buffer = try file.readToEndAlloc(allocator, stat.size);
    defer allocator.free(buffer);

    print("File size: {}\n", .{stat.size});

    // Iterate over the buffer
    var fileLines = std.mem.splitAny(u8, buffer, "\n");
    var lines = ArrayList([]u8).init(allocator);
    defer lines.deinit();
    print("Lines index: {?}\n", .{fileLines.index});
    while (fileLines.next()) |line| {
        lines.append(@constCast(line)) catch {
            print("failed to append line to arraylist after casting", .{});
        };
    }

    print("Number of lines: {}\n", .{lines.items.len});
    print("Now that we have lines, we can get started\n", .{});

    var puzzleGrid = ArrayList(ArrayList(u8)).init(allocator);
    var locationTracker = ArrayList(ArrayList(u8)).init(allocator);
    defer {
        for (puzzleGrid.items) |row| {
            row.deinit();
        }
        puzzleGrid.deinit();
        for (locationTracker.items) |row| {
            row.deinit();
        }
        locationTracker.deinit();
    }

    var guard = Guard{ .sign = ' ', .signChanges = false, .x = 0, .y = 0 };

    var emptyLine = ArrayList(u8).init(allocator);
    var emptyLocation = ArrayList(u8).init(allocator);
    for (0..lines.items[0].len + 2) |_| {
        try emptyLine.append('X');
        try emptyLocation.append(0);
    }
    try puzzleGrid.append(emptyLine);
    try locationTracker.append(emptyLocation);

    for (0.., lines.items) |y, line| {
        var puzzleLine = ArrayList(u8).init(allocator);
        var locationRow = ArrayList(u8).init(allocator);

        try puzzleLine.append('X');
        try locationRow.append(0);
        for (0.., line) |x, char| {
            try puzzleLine.append(char);
            try locationRow.append(0);
            if (char != '.' and char != '#') {
                guard.sign = char;
                guard.x = x + 1;
                guard.y = y + 1;
            }
        }
        try puzzleLine.append('X');
        try locationRow.append(0);
        try puzzleGrid.append(puzzleLine);
        try locationTracker.append(locationRow);
    }

    var endLine = ArrayList(u8).init(allocator);
    var endLocationLIne = ArrayList(u8).init(allocator);
    for (0..lines.items[0].len + 2) |_| {
        try endLine.append('X');
        try endLocationLIne.append(0);
    }
    try puzzleGrid.append(endLine);
    try locationTracker.append(endLocationLIne);

    print("Guard location: {}\n", .{guard});

    print("  ", .{});
    for (0..puzzleGrid.items[0].items.len) |i| {
        print("{x}", .{i});
    }
    print("\n", .{});
    for (0.., puzzleGrid.items) |i, puzzleLine| {
        print("{x} {s}\n", .{ i, puzzleLine.items });
    }
    // Print initial location tracker
    print("    ", .{});
    for (0..locationTracker.items[0].items.len) |i| {
        print("{x}, ", .{i});
    }
    print("\n", .{});
    for (0.., locationTracker.items) |i, locationLine| {
        print("{x} {any}\n", .{ i, locationLine.items });
    }

    var charToDir = std.AutoHashMap(u8, Direction).init(allocator);
    defer charToDir.deinit();

    try charToDir.put('^', Direction{ .x = &stay, .y = &dec, .next = '>' });
    try charToDir.put('<', Direction{ .x = &dec, .y = &stay, .next = '^' });
    try charToDir.put('>', Direction{ .x = &inc, .y = &stay, .next = 'v' });
    try charToDir.put('v', Direction{ .x = &stay, .y = &inc, .next = '<' });

    var isOut = false;
    while (!isOut) {
        // print("{}\n", .{guard});
        if (!guard.signChanges) {
            locationTracker.items[guard.y].items[guard.x] += 1;
        }
        guard.signChanges = false;
        // print("{any}\n", .{locationTracker.items[guard.y].items});

        if (charToDir.get(guard.sign)) |dir| {
            const nextX = dir.x(guard.x);
            const nextY = dir.y(guard.y);
            const nextSquare = puzzleGrid.items[nextY].items[nextX];
            if (nextSquare == '#') {
                guard.sign = dir.next;
                guard.signChanges = true;
            } else {
                guard.walk(dir);
            }
            if (nextSquare == 'X') {
                isOut = true;
            }
        }
    }
    print("Finally we are out\n", .{});
    // Print final location tracker
    print("    ", .{});
    for (0..locationTracker.items[0].items.len) |i| {
        print("{x}, ", .{i});
    }
    print("\n", .{});
    for (0.., locationTracker.items) |i, locationLine| {
        print("{x} {any}\n", .{ i, locationLine.items });
    }

    print("  ", .{});
    for (0..locationTracker.items[0].items.len) |i| {
        print("{x} ", .{i});
    }
    print("\n", .{});
    for (0..puzzleGrid.items.len) |y| {
        print("{x} ", .{y});
        for (0..puzzleGrid.items[0].items.len) |x| {
            const locationCntr = locationTracker.items[y].items[x];
            if (locationCntr > 0) {
                print("{} ", .{locationCntr});
            } else {
                const gridItem = puzzleGrid.items[y].items[x];
                if (gridItem != '.') {
                    print("{c} ", .{gridItem});
                } else {
                    print("  ", .{});
                }
            }
        }
        print("\n", .{});
    }

    var locationCounter: usize = 0;
    for (locationTracker.items) |row| {
        for (row.items) |loc| {
            if (loc != 0) {
                locationCounter += 1;
            }
        }
    }
    print("Unique locations: {}\n", .{locationCounter});
}

fn dec(inp: usize) usize {
    return inp - 1;
}

fn inc(inp: usize) usize {
    return inp + 1;
}

fn stay(inp: usize) usize {
    return inp;
}

const Direction = struct { x: *const fn (usize) usize, y: *const fn (usize) usize, next: u8 };
const Guard = struct {
    sign: u8,
    signChanges: bool,
    x: usize,
    y: usize,
    fn walk(self: *Guard, dir: Direction) void {
        self.x = dir.x(self.x);
        self.y = dir.y(self.y);
    }
};

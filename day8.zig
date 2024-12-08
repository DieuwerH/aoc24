const std = @import("std");
const dbg = std.debug;
const ArrayList = std.ArrayList;
const print = dbg.print;

pub fn main() !void {
    print("Hello Day 8\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        _ = gpa.deinit();
    }

    var path: [:0]u8 = undefined;
    // open file
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);
    if (args.len != 2) {
        print("Please provide an input file name\n", .{});
        return;
    } else {
        path = args[1];
    }
    for (args) |arg| {
        print("{s}\n", .{arg});
    }

    // const path = "input_day8_example.txt";
    // const path = "input_day8.txt";
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
    var antinodes = ArrayList(ArrayList(u8)).init(allocator);
    defer {
        for (puzzleGrid.items) |gridLine| {
            gridLine.deinit();
        }
        puzzleGrid.deinit();
        for (antinodes.items) |gridLine| {
            gridLine.deinit();
        }
        antinodes.deinit();
    }

    var antennas = std.AutoHashMap(u8, ArrayList(Coord)).init(allocator);
    defer {
        var it = antennas.iterator();
        while (it.next()) |antennaList| {
            antennaList.value_ptr.deinit();
        }
        antennas.deinit();
    }

    var antennaTypes = ArrayList(u8).init(allocator);
    defer antennaTypes.deinit();

    const maxX = lines.items[0].len;
    const maxY = lines.items.len;

    const bound = Coord{ .x = @intCast(maxX), .y = @intCast(maxY) };

    for (0.., lines.items) |y, inputLine| {
        try puzzleGrid.append(ArrayList(u8).init(allocator));
        try antinodes.append(ArrayList(u8).init(allocator));
        for (0.., inputLine) |x, chr| {
            try puzzleGrid.items[y].append(chr);
            try antinodes.items[y].append(chr);
            if (chr != '.') {
                const coord = Coord{ .x = @intCast(x), .y = @intCast(y) };
                // coord.prnt();
                // println();
                if (antennas.getPtr(chr)) |antenna| {
                    try antenna.*.append(coord);
                } else {
                    try antennaTypes.append(chr);
                    var antenna = ArrayList(Coord).init(allocator);
                    try antenna.append(coord);
                    try antennas.put(chr, antenna);
                }
            }
        }
    }

    for (antennaTypes.items) |antennaType| {
        // print("Antenna Type: {c}\n", .{antennaType});
        if (antennas.getPtr(antennaType)) |antenna| {
            for (0..antenna.items.len) |baseIndex| {
                var baseCoord = antenna.items[baseIndex];
                for (0..antenna.items.len) |otherIndex| {
                    var otherCoord = antenna.items[otherIndex];
                    if (!baseCoord.eq(&otherCoord)) {
                        var diff = baseCoord.diff(&otherCoord);
                        otherCoord.addToGrid(&antinodes);

                        diff.smallForm();

                        var shouldStop = false;
                        var lineCntr: isize = 1;
                        while (!shouldStop) {
                            const antiNode = baseCoord.addTimes(&diff, lineCntr);
                            if (antiNode.inBounds(&bound)) {
                                // print("Anti node of ", .{});
                                // baseCoord.prnt();
                                // print(" and ", .{});
                                // otherCoord.prnt();
                                // print(": ", .{});
                                // antiNode.prntln();
                                antiNode.addToGrid(&antinodes);
                                lineCntr += 1;
                            } else {
                                shouldStop = true;
                            }
                        }
                    }
                }
                // baseCoord.prnt();
            }
            println();
        }
    }
    // var it = antennas.iterator();
    // while (it.next()) |ant| {
    //     print("{any}: ", .{ant.key_ptr.*});
    //     for (ant.value_ptr.items) |coord| {
    //         coord.prnt();
    //     }
    //     println();
    // }

    var antiCntr: usize = 0;
    for (antinodes.items) |nodeLine| {
        for (nodeLine.items) |chr| {
            print("{c}", .{chr});
            if (chr == '#') {
                antiCntr += 1;
            }
        }
        print("\n", .{});
    }
    print("Total antinode locations: {}\n", .{antiCntr});
}

const Coord = struct {
    x: isize,
    y: isize,
    const Self = @This();
    fn diff(self: *Self, other: *Coord) Coord {
        return Coord{ .x = (self.x - other.x), .y = (self.y - other.y) };
    }
    fn addSelf(self: *Self, vector: *const Coord) void {
        self.*.x += vector.x;
        self.*.y += vector.y;
    }
    fn add(self: *Self, vector: *const Coord) Coord {
        return Coord{ .x = self.x + vector.x, .y = self.y + vector.y };
    }
    fn addTimes(self: *Self, vector: *const Coord, times: isize) Coord {
        return Coord{ .x = self.x + (vector.x * times), .y = self.y + (vector.y * times) };
    }
    fn eq(self: *Self, other: *const Coord) bool {
        return (self.x == other.x and self.y == other.y);
    }
    fn prnt(self: *const Self) void {
        print("({},{})", .{ self.x, self.y });
    }
    fn prntln(self: *const Self) void {
        self.prnt();
        println();
    }
    fn inBounds(self: *const Self, bound: *const Self) bool {
        return (self.x >= 0 and self.y >= 0 and self.x < bound.x and self.y < bound.y);
    }
    fn addToGrid(self: *const Self, grid: *ArrayList(ArrayList(u8))) void {
        const x: usize = @intCast(self.x);
        const y: usize = @intCast(self.y);
        grid.items[y].items[x] = '#';
    }
    fn smallForm(self: *Self) void {
        const absX: usize = @abs(self.x);
        const absY: usize = @abs(self.y);

        const greatestCommonDivisor = gcd(absX, absY);

        if (greatestCommonDivisor != 1) {
            self.prnt();
            print("We can decrease this ones size by dividing by {}\n", .{greatestCommonDivisor});
        }

        const gcdIsize: isize = @intCast(greatestCommonDivisor);

        self.*.x = @divFloor(self.x, gcdIsize);
        self.*.y = @divFloor(self.y, gcdIsize);
        // self.*.x /= gcdIsize;
        // self.*.y /= gcdIsize;
    }
};

fn gcd(a: usize, b: usize) usize {
    if (a == 0) {
        return b;
    }
    return gcd(b % a, a);
}

fn println() void {
    print("\n", .{});
}

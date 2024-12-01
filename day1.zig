const std = @import("std");
const dbg = std.debug;
const ArrayList = std.ArrayList;
const print = dbg.print;

pub fn main() !void {
    print("Hello Day 1\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        _ = gpa.deinit();
    }

    // open file
    // const path = "input_day1_example.txt";
    const path = "input_day1.txt";
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
        if (!std.mem.eql(u8, line, "")) {
            // print("{s}\n", .{line});
            lines.append(@constCast(line)) catch {
                print("failed to append line to arraylist after casting", .{});
            };
        }
    }

    // print("Line 0:\n{}\n", .{lines[0]});
    // print("Number of lines: {}", .{lines.items.len});
    print("Number of lines: {}\n", .{lines.items.len});
    print("Now that we have lines, we can get started\n", .{});

    var leftNumbers = ArrayList(i32).init(allocator);
    defer leftNumbers.deinit();
    var rightNumbers = ArrayList(i32).init(allocator);
    defer rightNumbers.deinit();

    for (lines.items) |line| {
        // print("{s}\n", .{line});
        var line_split = std.mem.splitScalar(u8, line, ' ');
        var foundFirst = false;
        while (line_split.next()) |sub_line| {
            if (sub_line.len > 0) {
                const number = try std.fmt.parseInt(i32, sub_line, 10);
                if (!foundFirst) {
                    try leftNumbers.append(number);
                    foundFirst = true;
                } else {
                    try rightNumbers.append(number);
                }
            }
        }
        // print("\n", .{});
    }

    // print("Left numbers: {any}\n", .{leftNumbers.items});
    // print("Right numbers: {any}\n", .{rightNumbers.items});

    std.sort.insertion(i32, leftNumbers.items, {}, std.sort.asc(i32));
    std.sort.insertion(i32, rightNumbers.items, {}, std.sort.asc(i32));
    // print("Sorted left numbers: {any}\n", .{leftNumbers.items});
    // print("Sorted right numbers: {any}\n", .{rightNumbers.items});

    var dif_sum: u32 = 0;
    for (0.., leftNumbers.items) |i, leftNum| {
        const rightNum = rightNumbers.items[i];
        // print("{}: {} - {}\n", .{ i, leftNum, rightNum });
        const diff: u32 = @abs(rightNum - leftNum);
        // print("Difference: {}\n", .{diff});
        dif_sum += diff;
    }

    print("Total difference: {}\n", .{dif_sum});

    print("part two (2):", .{});

    var leftHash = std.AutoHashMap(i32, i32).init(allocator);
    defer leftHash.deinit();
    for (leftNumbers.items) |lnum| {
        try leftHash.put(lnum, 0);
    }
    for (rightNumbers.items) |rnum| {
        const optNumCnt = leftHash.get(rnum);
        if (optNumCnt) |numCnt| {
            const res = numCnt + 1;
            try leftHash.put(rnum, res);
        }
    }

    // print("{}", .{leftHash});

    var part2counter: i32 = 0;
    for (leftNumbers.items) |lnum| {
        const optNumCount = leftHash.get(lnum);
        if (optNumCount) |numCount| {
            if (numCount > 0) {
                const partial_sim_score = lnum * numCount;
                part2counter += partial_sim_score;
            }
        }
    }

    print("Total similarity score: {}\n", .{part2counter});
}

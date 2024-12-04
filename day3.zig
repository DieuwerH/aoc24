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
    const path = "input_day3_example.txt";
    // const path = "input_day3.txt";
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

    print("Number of lines: {}\n", .{lines.items.len});
    print("Lines: {s}\n", .{lines.items});
    print("Now that we have lines, we can get started\n", .{});
}

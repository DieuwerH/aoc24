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
    // const path = "input_day2_example.txt";
    const path = "input_day2.txt";
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
    print("Now that we have lines, we can get started\n", .{});

    const minDelta = 1;
    const maxDelta = 3;
    var okLines: usize = 0;
    var lineCounter: isize = -1;
    for (lines.items) |line| {
        lineCounter += 1;
        // print("[!] Current line index: {}\n", .{lineCounter});
        const lineReults = checkLine(line, minDelta, maxDelta);
        if (lineReults.good) {
            okLines += 1;
            print("{}\n", .{lineCounter});
            // print("Line at {} is ok without modifications\n", .{lineCounter});
        } else {
            // BRUTE FORCE
            // const lineArrayList = lineToSplitArrayList(line);
            // for (0..lineArrayList.items.len) |itemIndex| {
            //     var lineArrayListInner = lineToSplitArrayList(line);
            //     _ = lineArrayListInner.orderedRemove(itemIndex);
            //     const res = checkLine2(lineArrayListInner, minDelta, maxDelta);
            //     if (res.good) {
            //         okLines += 1;
            //         break;
            //     }
            // }

            // print("Option 1: removing item at error\n", .{});
            var lineArrayList = lineToSplitArrayList(line);
            _ = lineArrayList.orderedRemove(lineReults.culprit);

            const opt1Result = checkLine2(lineArrayList, minDelta, maxDelta);
            if (opt1Result.good) {
                // print("removing the item at the error solves the issue\n", .{});
                okLines += 1;
                print("{}\n", .{lineCounter});
                continue;
            }
            // print("Option 2: removing item before error\n", .{});
            lineArrayList = lineToSplitArrayList(line);
            _ = lineArrayList.orderedRemove(lineReults.culprit - 1);

            const opt2Result = checkLine2(lineArrayList, minDelta, maxDelta);
            if (opt2Result.good) {
                // print("removing the item before the error solves the issue\n", .{});
                okLines += 1;
                print("{}\n", .{lineCounter});
                continue;
            }

            // print("Option 3: removing first item\n", .{});
            lineArrayList = lineToSplitArrayList(line);
            _ = lineArrayList.orderedRemove(0);

            const opt3Result = checkLine2(lineArrayList, minDelta, maxDelta);
            if (opt3Result.good) {
                print("removing the first item solves the issue");
                okLines += 1;
                print("{}\n", .{lineCounter});
                continue;
            }
        }
    }
    print("Number of lines that are ok: {}\n", .{okLines});
}

fn lineToSplitArrayList(line: []u8) std.ArrayList([]const u8) {
    const allocator = std.heap.page_allocator;
    var splitIt = std.mem.splitScalar(u8, line, ' ');
    var list = std.ArrayList([]const u8).init(allocator);

    while (splitIt.next()) |num| {
        list.append(num) catch {
            // print("Failed to append item to ArrayList\n", .{});
            continue;
        };
    }

    return list;
}

fn checkLine(line: []u8, min: i32, max: i32) struct { good: bool, culprit: usize } {
    // print("Line to check: {s}\n", .{line});
    var lineSplitIterator = std.mem.splitScalar(u8, line, ' ');

    var previous: i32 = 0;
    var foundFirstNum = false;
    var foundSecondNum: bool = false;
    var lineGood = true;
    var cmpFunc: *const fn (i32, i32, i32, i32) bool = isDecreasingProperly;
    var numIndex: usize = 0;
    var culprit: usize = 0;
    while (lineSplitIterator.next()) |level| {
        if (level.len == 0) {
            continue;
        }

        const levelNum = std.fmt.parseInt(i32, level, 10) catch {
            lineGood = false;
            // print("got an error in line: {s}", .{line});
            break;
        };
        if (!foundFirstNum) {
            previous = levelNum;
            foundFirstNum = true;
            numIndex += 1;
            continue;
        }
        if (!foundSecondNum) {
            if (levelNum < previous) {
                cmpFunc = isDecreasingProperly;
            } else {
                cmpFunc = isIncreasingProperly;
            }
            foundSecondNum = true;
        }
        const allGood = cmpFunc(previous, levelNum, min, max);
        if (allGood) {
            previous = levelNum;
        } else {
            lineGood = false;
            culprit = numIndex;
            break;
        }
        numIndex += 1;
    }
    return .{ .good = lineGood, .culprit = numIndex };
}

fn isDecreasingProperly(numA: i32, numB: i32, min: i32, max: i32) bool {
    const diff = numA - numB;
    return numB < numA and diff >= min and diff <= max;
}

fn isIncreasingProperly(numA: i32, numB: i32, min: i32, max: i32) bool {
    const diff = numB - numA;
    return numB > numA and diff >= min and diff <= max;
}

fn checkLine2(line: std.ArrayList([]const u8), min: i32, max: i32) struct { good: bool, culprit: usize } {
    // print("Line to check: {s}\n", .{line.items});
    var previous: i32 = 0;
    var foundFirstNum = false;
    var foundSecondNum: bool = false;
    var lineGood = true;
    var cmpFunc: *const fn (i32, i32, i32, i32) bool = isDecreasingProperly;
    var numIndex: usize = 0;
    var culprit: usize = 0;
    // while (lineSplitIterator.next()) |level| {
    for (line.items) |level| {
        if (level.len == 0) {
            continue;
        }

        const levelNum = std.fmt.parseInt(i32, level, 10) catch {
            lineGood = false;
            break;
        };
        if (!foundFirstNum) {
            previous = levelNum;
            foundFirstNum = true;
            numIndex += 1;
            continue;
        }
        if (!foundSecondNum) {
            if (levelNum < previous) {
                cmpFunc = isDecreasingProperly;
            } else {
                cmpFunc = isIncreasingProperly;
            }
            foundSecondNum = true;
        }
        const allGood = cmpFunc(previous, levelNum, min, max);
        if (allGood) {
            previous = levelNum;
        } else {
            lineGood = false;
            culprit = numIndex;
            break;
        }
        numIndex += 1;
    }
    return .{ .good = lineGood, .culprit = numIndex };
}

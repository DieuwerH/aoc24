const std = @import("std");
const dbg = std.debug;
const ArrayList = std.ArrayList;
const print = dbg.print;

pub fn main() !void {
    print("Hello Day 7\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        _ = gpa.deinit();
    }

    // open file
    // const path = "input_day7_example.txt";
    const path = "input_day7.txt";
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

    var equations = ArrayList(Equation).init(allocator);
    defer {
        for (equations.items) |eq| {
            eq.deinit();
        }
        equations.deinit();
    }

    for (lines.items) |line| {
        // print("{s}\n", .{line});
        const newEq = Equation.fromLine(line, allocator);
        // const moreEqs = Equation.fromLine2(line, allocator);
        try equations.append(newEq);
        // for (moreEqs.items) |meq| {
        // try equations.append(meq);
        // }
        // moreEqs.deinit();
    }

    print("Created array of equations.\n", .{});

    var cntr: usize = 0;
    // for (0.., equations.items) |i, eq| {
    for (equations.items) |eq| {
        // print("\t", .{});
        // eq.print();
        const eqIsPossible = eq.bruteforce();
        if (eqIsPossible) {
            cntr += eq.TestValue;
            // print("This one is possible\n", .{});
        }
        // else {
        //     print("\t\tTrying permutations\n", .{});
        //     const moreEqs = Equation.fromLine2(lines.items[i], allocator);
        //     defer {
        //         for (moreEqs.items) |item| {
        //             item.deinit();
        //         }
        //         moreEqs.deinit();
        //     }
        //     for (moreEqs.items) |meq| {
        //         print("\tMEQ: ", .{});
        //         meq.print();
        //         const meqIsPossible = meq.bruteforce();
        //         if (meqIsPossible) {
        //             cntr += eq.TestValue;
        //             print("This meq is possible\n", .{});
        //             break;
        //         }
        //     }
        // }
    }
    print("Total calibration {}\n", .{cntr});
}

const Equation = struct {
    TestValue: usize,
    TestInputs: ArrayList(usize),
    fn new(allocator: std.mem.Allocator) Equation {
        const equation = Equation{ .TestValue = 0, .TestInputs = ArrayList(usize).init(allocator) };
        return equation;
    }
    fn deinit(self: *const Equation) void {
        self.*.TestInputs.deinit();
    }
    fn fromLine(line: []u8, allocator: std.mem.Allocator) Equation {
        var res = Equation.new(allocator);

        res.TestValue = 10;

        var lineIterator = std.mem.splitSequence(u8, line, ": ");

        var foundValue = false;
        while (lineIterator.next()) |linepart| {
            // std.debug.print("{s}\n", .{linepart});
            if (!foundValue) {
                const lineValue = std.fmt.parseInt(usize, linepart, 10) catch {
                    std.debug.print("Something went wrong while parsing {s}\n", .{linepart});
                    break;
                };
                res.TestValue = lineValue;
                foundValue = true;
            } else {
                var itemsIterator = std.mem.splitScalar(u8, linepart, ' ');
                while (itemsIterator.next()) |item| {
                    const itemNum = std.fmt.parseInt(usize, item, 10) catch {
                        std.debug.print("Something went wrong while parsing {s}\n", .{item});
                        break;
                    };
                    res.TestInputs.append(itemNum) catch {
                        std.debug.print("Something went wrong while appending\n", .{});
                        break;
                    };
                }
            }
        }
        return res;
    }
    fn fromLine2(line: []u8, allocator: std.mem.Allocator) ArrayList(Equation) {
        var lineValue: usize = 0;
        var lineIterator = std.mem.splitSequence(u8, line, ": ");
        var foundValue = false;

        var resultSet = ArrayList(Equation).init(allocator);

        while (lineIterator.next()) |linepart| {
            if (!foundValue) {
                lineValue = std.fmt.parseInt(usize, linepart, 10) catch {
                    std.debug.print("Something went wrong while parsing {s}\n", .{linepart});
                    break;
                };
                foundValue = true;
            } else {
                var lineArray = ArrayList(u8).init(allocator);
                defer lineArray.deinit();
                var space_counter: usize = 0;
                for (linepart) |char| {
                    lineArray.append(char) catch {
                        std.debug.print("oh noes", .{});
                    };
                    if (char == ' ') {
                        space_counter += 1;
                    }
                }

                for (0..space_counter) |space_target| {
                    var spaces_seen: usize = 0;
                    var res = Equation.new(allocator);
                    res.TestValue = lineValue;

                    for (0.., linepart) |templineindex, chr| {
                        if (chr == ' ') {
                            if (spaces_seen == space_target) {
                                lineArray.items[templineindex] = '_';
                                break;
                            } else {
                                lineArray.items[templineindex] = ' ';
                                spaces_seen += 1;
                            }
                        }
                    }

                    var itemsIterator = std.mem.splitScalar(u8, lineArray.items, ' ');
                    while (itemsIterator.next()) |item| {
                        const itemNum = std.fmt.parseInt(usize, item, 10) catch {
                            std.debug.print("Something went wrong while parsing {s}\n", .{item});
                            break;
                        };
                        res.TestInputs.append(itemNum) catch {
                            std.debug.print("Something went wrong while appending\n", .{});
                            break;
                        };
                    }
                    resultSet.append(res) catch {
                        std.debug.print("Something went wrong while saving result to result set", .{});
                    };
                }
            }
        }
        return resultSet;
    }
    fn print(self: *const Equation) void {
        std.debug.print("Value: {any} - Nums {any}\n", .{ self.TestValue, self.TestInputs.items });
    }
    fn bruteforce(self: *const Equation) bool {
        // self.print();
        return attempt(self.TestInputs.items[0], self.TestInputs.items[1..], self.TestValue);
    }
};

fn attempt(current: usize, rest: []usize, target: usize) bool {
    // print("Current {} - Target {} - rest {any}\n", .{ current, target, rest });
    if (rest.len == 0) {
        // print("in edgecase\n", .{});
        return current == target;
    }
    // if (rest.len == 1) {
    //     return (current * rest[0] == target or current + rest[0] == target);
    // }
    const addOption = current + rest[0];
    const mulOption = current * rest[0];
    var buf: [20]u8 = undefined;
    const concatOptionSlice = std.fmt.bufPrint(&buf, "{}{}", .{ current, rest[0] }) catch {
        std.debug.print("oh no not again\n", .{});
        return false;
    };
    const concatOption = std.fmt.parseInt(usize, concatOptionSlice, 10) catch {
        std.debug.print("could not convert to number\n", .{});
        return false;
    };
    const newRest = rest[1..];
    return (attempt(addOption, newRest, target) or attempt(mulOption, newRest, target) or attempt(concatOption, newRest, target));
}

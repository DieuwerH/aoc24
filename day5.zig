const std = @import("std");
const dbg = std.debug;
const ArrayList = std.ArrayList;
const print = dbg.print;

pub fn main() !void {
    print("Hello Day 5\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        _ = gpa.deinit();
    }

    // open file
    // const path = "input_day5_example.txt";
    const path = "input_day5.txt";
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

    var orderRules: std.AutoHashMap(u8, ArrayList(u8)) = std.AutoHashMap(u8, ArrayList(u8)).init(allocator);
    defer {
        var it = orderRules.iterator();
        while (it.next()) |entry| {
            entry.value_ptr.deinit();
        }
        orderRules.deinit();
    }

    var pages: std.ArrayList(std.ArrayList(u8)) = std.ArrayList(ArrayList(u8)).init(allocator);
    defer {
        for (pages.items) |page| {
            page.deinit();
        }
        pages.deinit();
    }

    var parseOrderRules = true;

    var goodPages: ArrayList(ArrayList(u8)) = ArrayList(ArrayList(u8)).init(allocator);
    defer {
        for (goodPages.items) |page| {
            page.deinit();
        }
        goodPages.deinit();
    }
    var badPages: ArrayList(ArrayList(u8)) = ArrayList(ArrayList(u8)).init(allocator);
    defer {
        for (badPages.items) |page| {
            page.deinit();
        }
        badPages.deinit();
    }

    for (lines.items) |line| {
        if (line.len == 0) {
            parseOrderRules = false;
            continue;
        }
        if (parseOrderRules) {
            var pageNumRule = std.mem.splitScalar(u8, line, '|');
            var pageNumRuleArray: ArrayList(u8) = std.ArrayList(u8).init(allocator);
            defer pageNumRuleArray.deinit();
            while (pageNumRule.next()) |ruleNum| {
                const asInt = try std.fmt.parseInt(u8, ruleNum, 10);
                try pageNumRuleArray.append(asInt);
            }

            if (orderRules.getPtr(pageNumRuleArray.items[1])) |ruleForPage| {
                try ruleForPage.*.append(pageNumRuleArray.items[0]);
            } else {
                var rulesForPage = std.ArrayList(u8).init(allocator);
                try rulesForPage.append(pageNumRuleArray.items[0]);
                try orderRules.put(pageNumRuleArray.items[1], rulesForPage);
            }
        } else {
            // print("Line: {s}\n", .{line});
            var pageOrder = std.mem.splitScalar(u8, line, ',');
            var curPage = ArrayList(u8).init(allocator);

            var goodOrder = true;

            var forbiddenPages: std.ArrayList(u8) = std.ArrayList(u8).init(allocator);
            defer forbiddenPages.deinit();
            while (pageOrder.next()) |page| {
                const pageIndex = try std.fmt.parseInt(u8, page, 10);
                try curPage.append(pageIndex);
                // print("Current page index: {}\n", .{pageIndex});

                if (contains(forbiddenPages, pageIndex)) {
                    goodOrder = false;
                    // break;
                }

                if (goodOrder) {
                    if (orderRules.get(pageIndex)) |newForbiddenNumbers| {
                        // print("Adding forbidden numbers:", .{});
                        for (newForbiddenNumbers.items) |num| {
                            if (!contains(forbiddenPages, num)) {
                                // print("{}, ", .{num});
                                try forbiddenPages.append(num);
                            }
                        }
                        // print("\n ", .{});
                    } else {
                        continue;
                    }
                }
            }

            if (goodOrder) {
                try goodPages.append(curPage);
            } else {
                try badPages.append(curPage);
            }
        }
    }

    print("Total number of good pages: {}\n", .{goodPages.items.len});

    var middleSum: usize = 0;
    for (goodPages.items) |page| {
        const pageLength = page.items.len;

        const halfWay = pageLength / 2;
        const middleNum = page.items[halfWay];
        // print("Number in the middle (index {}) is {} at line {any}\n", .{ halfWay, middleNum, page.items });
        middleSum += middleNum;
    }
    print("Sum 1: {}\n", .{middleSum});

    var middleSum2: usize = 0;
    for (badPages.items) |page| {
        // print("Page to fix: {any}\n", .{page.items});
        var incorrect = true;
        var currTry = page;
        while (incorrect) {
            var forbiddenPages: std.ArrayList(u8) = std.ArrayList(u8).init(allocator);
            defer forbiddenPages.deinit();
            var fixed = true;
            for (0.., currTry.items) |index, pageNum| {
                if (contains(forbiddenPages, pageNum)) {
                    currTry.items[index] = currTry.items[index - 1];
                    currTry.items[index - 1] = pageNum;
                    fixed = false;
                    break;
                }

                if (orderRules.get(pageNum)) |newForbiddenNumbers| {
                    // print("Adding forbidden numbers:", .{});
                    for (newForbiddenNumbers.items) |num| {
                        if (!contains(forbiddenPages, num)) {
                            // print("{}, ", .{num});
                            try forbiddenPages.append(num);
                        }
                    }
                } else {
                    continue;
                }
            }
            if (fixed) {
                incorrect = false;
            }
        }
        // print("Fixed order: {any}\n", .{currTry.items});
        const pageLength = currTry.items.len;
        const halfWay = pageLength / 2;
        const middleNum = currTry.items[halfWay];
        // print("Number in the middle (index {}) is {} at line {any}\n", .{ halfWay, middleNum, page.items });
        middleSum2 += middleNum;
        // currTry.deinit();
    }
    print("Sum 2: {}\n", .{middleSum2});
}

fn contains(forbiddenPages: std.ArrayList(u8), pageIndex: u8) bool {
    var found: bool = false;

    for (forbiddenPages.items) |page| {
        if (pageIndex == page) {
            found = true;
            break;
        }
    }

    return found;
}

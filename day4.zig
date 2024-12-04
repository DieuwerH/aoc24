const std = @import("std");
const dbg = std.debug;
const ArrayList = std.ArrayList;
const print = dbg.print;

pub fn main() !void {
    print("Hello Day 4\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        _ = gpa.deinit();
    }

    // open file
    // const path = "input_day4_example.txt";
    const path = "input_day4.txt";
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

    var puzzleGrid = ArrayList(ArrayList(u8)).init(allocator);
    var debugGrid = ArrayList(ArrayList(u8)).init(allocator);
    defer {
        for (puzzleGrid.items) |puzzleLine| {
            puzzleLine.deinit();
        }
        puzzleGrid.deinit();

        for (debugGrid.items) |line| {
            line.deinit();
        }
        debugGrid.deinit();
    }

    const lineLength = lines.items.len;

    for (lineLength + 6) |_| {
        var emptyList = ArrayList(u8).init(allocator);
        for (lines.items[0].len + 6) |_| {
            try emptyList.append(' ');
        }
        try debugGrid.append(emptyList);
    }

    // start with three empty lines
    for (0..3) |_| {
        var emptyList = ArrayList(u8).init(allocator);
        for (lineLength + 6) |_| {
            try emptyList.append(' ');
        }
        try puzzleGrid.append(emptyList);
    }

    // add the lines to the grid
    for (lines.items) |line| {
        var puzzleLine = ArrayList(u8).init(allocator);

        for (0..3) |_| {
            try puzzleLine.append(' ');
        }

        for (line) |char| {
            try puzzleLine.append(char);
        }

        for (0..3) |_| {
            try puzzleLine.append(' ');
        }

        try puzzleGrid.append(puzzleLine);
    }

    // finish with three empty lines
    for (0..3) |_| {
        var emptyList = ArrayList(u8).init(allocator);
        for (lineLength + 6) |_| {
            try emptyList.append(' ');
        }
        try puzzleGrid.append(emptyList);
    }

    print("   0123456789ABCDEF\n", .{});
    for (0.., puzzleGrid.items) |i, puzzleLine| {
        print("[{x}]{s}\n", .{ i, puzzleLine.items });
    }

    print("Do the checks\n", .{});

    // // create isize array;
    // var rowIndices: ArrayList(isize) = ArrayList(isize).init(allocator);
    // defer rowIndices.deinit();
    // var colIndices: ArrayList(isize) = ArrayList(isize).init(allocator);
    // defer colIndices.deinit();

    var xmasCounter: usize = 0;
    var xmasses: usize = 0;
    for (0..puzzleGrid.items.len) |rowIndex| {
        for (0..puzzleGrid.items[0].items.len) |colIndex| {
            const xmasMatches = search(puzzleGrid, rowIndex, colIndex, &debugGrid);
            xmasCounter += xmasMatches;

            const xmas = searchXdashMAS(puzzleGrid, rowIndex, colIndex);
            if (xmas) {
                xmasses += 1;
            }
        }
    }

    print("Total XMAS occurence: {}\n", .{xmasCounter});

    print("   0123456789ABCDEF\n", .{});
    for (0.., debugGrid.items) |i, puzzleLine| {
        print("[{x}]{s}\n", .{ i, puzzleLine.items });
    }

    print("Total X-MAS occurence: {}\n", .{xmasses});
}

fn search(grid: ArrayList(ArrayList(u8)), row: usize, col: usize, dbgGrid: *ArrayList(ArrayList(u8))) usize {
    const curChar = grid.items[row].items[col];
    if (curChar != 'X') {
        return 0;
    }

    const xDirs: [3]isize = [_]isize{ -1, 0, 1 };
    const yDirs: [3]isize = [_]isize{ -1, 0, 1 };

    var matches: usize = 0;
    for (xDirs) |xDir| {
        for (yDirs) |yDir| {
            const match = searchDir(grid, row, col, xDir, yDir, dbgGrid);
            if (match) {
                // print("match at {x},{x} in dir {},{}\n", .{ col, row, xDir, yDir });
                matches += 1;
            }
        }
    }
    return matches;
}

fn searchDir(grid: ArrayList(ArrayList(u8)), row: usize, col: usize, xDir: isize, yDir: isize, dbgGrid: *ArrayList(ArrayList(u8))) bool {
    const iRow: isize = @intCast(row);
    const iCol: isize = @intCast(col);

    const letterTwo = grid.items[@intCast(iRow + xDir)].items[@intCast(iCol + yDir)];
    if (letterTwo != 'M') return false;
    const letterThree = grid.items[@intCast(iRow + (2 * xDir))].items[@intCast(iCol + (2 * yDir))];
    if (letterThree != 'A') return false;
    const letterFour = grid.items[@intCast(iRow + (3 * xDir))].items[@intCast(iCol + (3 * yDir))];
    if (letterFour != 'S') return false;

    dbgGrid.items[row].items[col] = 'X';
    dbgGrid.items[@intCast(iRow + xDir)].items[@intCast(iCol + yDir)] = 'M';
    dbgGrid.items[@intCast(iRow + 2 * xDir)].items[@intCast(iCol + 2 * yDir)] = 'A';
    dbgGrid.items[@intCast(iRow + 3 * xDir)].items[@intCast(iCol + 3 * yDir)] = 'S';
    return true;
}

fn searchXdashMAS(grid: ArrayList(ArrayList(u8)), row: usize, col: usize) bool {
    const curChar = grid.items[row].items[col];
    if (curChar != 'A') {
        return false;
    }

    const match = searchDiagonalMAX(grid, row, col);
    return match;
}

fn searchDiagonalMAX(grid: ArrayList(ArrayList(u8)), row: usize, col: usize) bool {
    const opt1 = grid.items[row - 1].items[col - 1] == 'M' and grid.items[row + 1].items[col + 1] == 'S';
    const opt2 = grid.items[row - 1].items[col + 1] == 'M' and grid.items[row + 1].items[col - 1] == 'S';
    const opt3 = grid.items[row + 1].items[col - 1] == 'M' and grid.items[row - 1].items[col + 1] == 'S';
    const opt4 = grid.items[row + 1].items[col + 1] == 'M' and grid.items[row - 1].items[col - 1] == 'S';

    return (opt1 or opt4) and (opt2 or opt3);
}

fn searchDir2(grid: ArrayList(ArrayList(u8)), row: usize, col: usize, xDir: isize, yDir: isize, dbgGrid: *ArrayList(ArrayList(u8))) bool {
    const iRow: isize = @intCast(row);
    const iCol: isize = @intCast(col);

    const letterTwo = grid.items[@intCast(iRow + xDir)].items[@intCast(iCol + yDir)];
    if (letterTwo != 'A') return false;
    const letterThree = grid.items[@intCast(iRow + (2 * xDir))].items[@intCast(iCol + (2 * yDir))];
    if (letterThree != 'S') return false;

    const letterFour = grid.items[@intCast(iRow + (3 * xDir))].items[@intCast(iCol + (3 * yDir))];
    if (letterFour != 'S') return false;

    dbgGrid.items[row].items[col] = 'X';
    dbgGrid.items[@intCast(iRow + xDir)].items[@intCast(iCol + yDir)] = 'M';
    dbgGrid.items[@intCast(iRow + 2 * xDir)].items[@intCast(iCol + 2 * yDir)] = 'A';
    dbgGrid.items[@intCast(iRow + 3 * xDir)].items[@intCast(iCol + 3 * yDir)] = 'S';
    return true;
}

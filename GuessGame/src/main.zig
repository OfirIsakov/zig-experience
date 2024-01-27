const std = @import("std");
const fmt = std.fmt;
const prng = std.rand.DefaultPrng;
const time = std.time;

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    const currentTime: time.Instant = try time.Instant.now();
    var rnd = prng.init(currentTime.timestamp);
    const number = rnd.random().uintAtMost(u8, 99) + 1;

    var gameOver: bool = false;
    var guess: u8 = undefined;
    var guessCount: u32 = 0;

    while (!gameOver) {
        try stdout.print("Guess a number between 1 and 100: ", .{});
        guess = try getGuess();

        if (guess > number) try stdout.print("Your guess is too high\n", .{});
        if (guess < number) try stdout.print("Your guess is too low\n", .{});
        if (guess == number) gameOver = true;
        guessCount += 1;
    }

    try stdout.print("Winner!\n{} guesses", .{guessCount});
}

fn getGuess() !u8 {
    const stdin = std.io.getStdIn().reader();
    const stdout = std.io.getStdOut().writer();

    // size 6 for 3 letters + CRLF + 1 byte buffer
    var line_buf: [6]u8 = undefined;

    const read_amount = try stdin.read(&line_buf);
    if (read_amount == line_buf.len) {
        try stdout.print("Input too long.\n", .{});
        return @as(i64, 0);
    }

    // trim CRLF from input
    const line = std.mem.trimRight(u8, line_buf[0..read_amount], "\r\n");

    // parse guessed number
    return fmt.parseUnsigned(u8, line, 10) catch {
        try stdout.print("Invalid input!\n", .{});
        return @as(u8, 0);
    };
}

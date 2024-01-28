// Turns out async is not entirly implemnted in ZIG :(
// So this is not compiling in 0.11.0
const std = @import("std");
const net = std.net;

const buffer_size = 1000;
const addr = net.Address.initIp4(.{ 0, 0, 0, 0 }, 10006);

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    const options = net.StreamServer.Options{};
    var server = net.StreamServer.init(options);
    defer server.deinit();
    // Listening
    _ = try server.listen(addr);

    std.debug.print("Server is listening on: {any}\n", .{addr});
    while (true) {
        const connection = try server.accept();

        const client = try allocator.create(Client);
        defer client;
        client.* = Client{
            .connection = connection,
            .handle_frame = async client.handle(),
        };

        async client.handle() catch |err| {
            std.debug.print("Client disconnected with error: {s}.\n", .{
                @errorName(err),
            });
            continue;
        };
    }
}

const Client = struct {
    connection: net.StreamServer.Connection,
    handle_frame: @Frame(Client.handle),

    fn handle(self: *Client) !void {
        const client_addr = self.connection.address;
        const stream = self.connection.stream;

        std.debug.print("Client connected from {any}.\n", .{client_addr});

        _ = try stream.write("Welcome to the chat server\n");

        while (true) {
            var buffer: [buffer_size]u8 = undefined;

            const len = try stream.read(&buffer);
            if (len == 0)
                break;

            // we ignore the amount of data sent.
            std.debug.print("{s} sent \"{s}\"\n", .{buffer[0..len]});
            _ = try stream.write(buffer[0..len]);
        }

        std.debug.print("Client disconnected.\n", .{});
    }
};

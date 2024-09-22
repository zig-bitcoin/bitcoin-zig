const std = @import("std");
const Hash = std.crypto.hash.sha2.Sha256;
const testing = std.testing;
const Midstate = @import("./sha256.zig");
const HashEngine = @import("./sha256.zig");

fn sha256t_tag(comptime tag: []const u8) [8]u32 {
    var h = Hash.init(.{});
    h.update(tag);
    const digest1 = h.finalResult();

    var h2 = Hash.init(.{});
    h2.update(&digest1);
    const digest2 = h2.finalResult();

    var midstate: [8]u32 = undefined;

    var i: usize = 0;
    while (i < 8) : (i += 1) {
        const idx = i * 4;
        midstate[i] = (@as(u32, digest2[idx]) << 24) |
            (@as(u32, digest2[idx + 1]) << 16) |
            (@as(u32, digest2[idx + 2]) << 8) |
            (@as(u32, digest2[idx + 3]));
    }

    return midstate;
}

const Tag = struct {
    engine: fn () Hash,
};

pub const Sha256t = struct {
    const Self = @This();

    sha256_engine: Hash,

    pub fn init() Self {
        return Sha256t{
            .sha256_engine = Hash.init(.{}),
        };
    }
};

const TestHashTag = struct {
    fn engine() Hash {
        const TEST_MIDSTATE = [32]u8{
            156, 224, 228, 230, 124, 17,  108, 57, 56,  179, 202, 242, 195, 15, 80, 137, 211, 243, 147,
            108, 71,  99,  110, 96,  125, 179, 62, 234, 221, 198, 240, 201,
        };

        var sha256_engine = Hash.init(.{});
        sha256_engine.update(&TEST_MIDSTATE);
        return sha256_engine;
    }
};

// Define the TestHash struct
const TestHash = struct {
    data: [32]u8,

    // Hash some bytes and create a new TestHash
    pub fn hash(data: []const u8) TestHash {
        var sha256_engine = TestHashTag.engine();
        sha256_engine.input(data);

        // Debugging: Print engine state after update
        std.debug.print("Engine state after update: {x}\n", .{sha256_engine.s});

        var out: [32]u8 = undefined;
        sha256_engine.final(&out);

        // Debugging: Print final hash output
        std.debug.print("Final hash output: {x}\n", .{out});

        return TestHash{ .data = out };
    }
};

test "manually created sha256t hash type" {
    var hash = TestHash.hash(&[_]u8{0});
    try std.testing.expectEqualSlices(u8, &[32]u8{
        0xed, 0x13, 0x82, 0x03, 0x78, 0x00, 0xc9, 0xdd, 0x93, 0x8d, 0xd8, 0x85, 0x4f, 0x1a, 0x88, 0x63,
        0xbc, 0xde, 0xb6, 0x70, 0x50, 0x69, 0xb4, 0xb5, 0x6a, 0x66, 0xec, 0x22, 0x51, 0x9d, 0x58, 0x29,
    }, &hash.data);

    std.debug.print("Test passed: Hash matches expected value.\n", .{});
}

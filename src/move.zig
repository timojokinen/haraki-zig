pub const MAX_MOVES = 256;

pub const MoveFlags = enum(u4) {
    QUIET = 0, // 0
    DOUBLE_PAWN_PUSH = 0b0001, // 1
    KING_CASTLE = 0b0010, // 2
    QUEEN_CASTLE = 0b0011, // 3
    CAPTURE = 0b0100, // 4
    EP_CAPTURE = 0b0101, // 5
    KNIGHT_PROMOTION = 0b1000, // 8
    BISHOP_PROMOTION = 0b1001, // 9
    ROOK_PROMOTION = 0b1010, // 10
    QUEEN_PROMOTION = 0b1011, // 11
    KNIGHT_PROMOTION_CAPTURE = 0b1100, // 12
    BISHOP_PROMOTION_CAPTURE = 0b1101, // 13
    ROOK_PROMOTION_CAPTURE = 0b1110, // 14
    QUEEN_PROMOTION_CAPTURE = 0b1111, // 15
};

pub const Move = packed struct(u16) {
    from_sq: u6,
    to_sq: u6,
    flags: MoveFlags,

    pub fn toU16(self: *const Move) u16 {
        return @bitCast(self.*);
    }
};

pub const ScoredMove = struct { move: Move, score: i32 };

pub const MoveList = struct {
    moves: [MAX_MOVES]ScoredMove = undefined,
    count: usize = 0,

    pub fn add(self: *MoveList, move: Move) void {
        self.moves[self.count] = .{ .move = move, .score = 0 };
        self.count += 1;
    }

    pub fn pickNext(self: *MoveList, start: usize) ScoredMove {
        var best_idx = start;
        var best_score = self.moves[start].score;
        var i = start + 1;

        while (i < self.count) : (i += 1) {
            if (self.moves[i].score > best_score) {
                best_score = self.moves[i].score;
                best_idx = i;
            }
        }

        const tmp = self.moves[start];
        self.moves[start] = self.moves[best_idx];
        self.moves[best_idx] = tmp;
        return self.moves[start];
    }
};

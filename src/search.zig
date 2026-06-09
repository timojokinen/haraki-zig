const std = @import("std");
const Position = @import("position.zig").Position;
const Move = @import("move.zig").Move;
const MoveList = @import("move.zig").MoveList;
const ScoredMove = @import("move.zig").ScoredMove;
const eval = @import("eval.zig").eval;
const Color = @import("utils.zig").Color;
const scoreMoves = @import("movepick.zig").scoreMoves;

const INF: i32 = 32_000;
const MATE: i32 = 30_000;

pub const Searcher = struct {
    best_move: ?Move = null,
    best_score: i32 = -INF,

    pub fn think(self: *Searcher, position: *Position, max_depth: usize) !Move {
        if (max_depth == 0) return error.InvalidDepth;
        var d: usize = 1;

        while (d <= max_depth) : (d += 1) {
            self.best_score = try negamax(self, position, -INF, INF, d, 0);
        }

        return self.best_move.?;
    }

    pub fn negamax(self: *Searcher, position: *Position, alpha: i32, beta: i32, depth: usize, ply: usize) !i32 {
        if (depth == 0) return quiescenceSearch(self, position, alpha, beta, ply);
        var move_list = try position.generateMoves();
        scoreMoves(self, position, &move_list);

        if (move_list.count == 0) {
            if (!position.inCheck()) return 0; // Stalemate
            return -MATE + @as(i32, @intCast(ply));
        }

        var max: i32 = -INF;
        var a = alpha;

        var i: usize = 0;
        while (i < move_list.count) : (i += 1) {
            const sm = move_list.pickNext(i);
            try position.makeMove(sm.move);
            const score = -(try negamax(self, position, -beta, -a, depth - 1, ply + 1));
            try position.unmakeMove(sm.move);

            if (score > max) {
                max = score;
                if (ply == 0) self.best_move = sm.move;
                if (score > a) {
                    a = score;
                }
            }

            if (score >= beta) return max;
        }

        return max;
    }

    fn quiescenceSearch(self: *Searcher, position: *Position, alpha_: i32, beta: i32, ply: usize) !i32 {
        const static_eval = eval(position);
        if (static_eval >= beta) return static_eval;
        var alpha: i32 = if (static_eval > alpha_) static_eval else alpha_;

        var move_list = try position.generateMoves();
        filterCaptures(&move_list);
        scoreMoves(self, position, &move_list);

        var max = static_eval;
        var i: usize = 0;
        while (i < move_list.count) : (i += 1) {
            const sm = move_list.pickNext(i);
            try position.makeMove(sm.move);
            const score = -(try quiescenceSearch(self, position, -beta, -alpha, ply + 1));
            try position.unmakeMove(sm.move);
            if (score >= beta) return score;
            if (score > max) max = score;
            if (score > alpha) alpha = score;
        }
        return max;
    }
};

fn filterCaptures(move_list: *MoveList) void {
    var w: usize = 0;
    for (move_list.moves[0..move_list.count]) |m| {
        const flags = @intFromEnum(m.move.flags);
        if ((flags & 0b1100) != 0) { // capture or promotion bit
            move_list.moves[w] = m;
            w += 1;
        }
    }
    move_list.count = w;
}

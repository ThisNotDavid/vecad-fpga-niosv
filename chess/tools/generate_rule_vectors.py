"""Independent reference vectors; python-chess is a development-only dependency."""
from pathlib import Path
import random
import sys
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'build/test_deps'))
import chess

def packed(board):
    return sum((p.piece_type | (8 if p.color==chess.BLACK else 0))<<(4*s) for s,p in board.piece_map().items())
def rights(board):
    return (int(board.has_kingside_castling_rights(chess.WHITE)) |
            int(board.has_queenside_castling_rights(chess.WHITE))<<1 |
            int(board.has_kingside_castling_rights(chess.BLACK))<<2 |
            int(board.has_queenside_castling_rights(chess.BLACK))<<3)

def main():
    rng=random.Random(9102026)
    fens=[chess.STARTING_FEN,
        'r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1',
        'r3k2r/8/8/8/8/8/8/R3K2R b KQkq - 0 1',
        '4kr2/8/8/8/8/8/8/R3K2R w KQ - 0 1',
        '4k3/8/8/8/8/8/4r3/R3K2R w KQ - 0 1',
        'k7/8/8/4KPpr/8/8/8/8 w - g6 0 1',
        '4k3/8/8/3pP3/8/8/8/4K3 w - d6 0 1',
        '4k3/8/8/8/3Pp3/8/8/4K3 b - d3 0 1',
        '4k3/P6r/8/8/8/8/7p/4K3 w - - 0 1',
        '4k3/P7/8/8/8/8/p6R/4K3 b - - 0 1',
        '4r1k1/8/8/8/8/8/4R3/4K3 w - - 0 1',
        '7k/6Q1/5K2/8/8/8/8/8 b - - 0 1',
        '7k/5K2/6Q1/8/8/8/8/8 b - - 0 1',
        'r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - 0 1']
    boards=[chess.Board(f) for f in fens]
    for game in range(4):
        b=chess.Board()
        for ply in range(100):
            legal=list(b.legal_moves)
            if not legal: break
            b.push(rng.choice(legal))
            if ply%5==0: boards.append(b.copy())
    out=ROOT/'build/rule_vectors.txt'; count=0
    with out.open('w') as f:
        for index,b in enumerate(boards):
            legal_moves=set(b.legal_moves)
            moves=set(legal_moves)
            # Every source/destination pair for targeted edge cases; samples for random games.
            if index<len(fens):
                moves.update(chess.Move(s,d,promotion=chess.QUEEN if b.piece_type_at(s)==chess.PAWN and chess.square_rank(d) in (0,7) else None)
                             for s in range(64) for d in range(64) if s!=d)
            else:
                moves.update(chess.Move(rng.randrange(64),rng.randrange(64)) for _ in range(128))
            for move in sorted(moves,key=lambda m:m.uci()):
                # Require standard e1-g1/e1-c1 castling coordinates. python-chess's
                # is_legal also accepts king-to-rook aliases for interoperability.
                legal=move in legal_moves; after=b.copy()
                if legal: after.push(move)
                # Default promotion request is queen; avoid mismatched malformed pawn requests.
                if not move.promotion and b.piece_type_at(move.from_square)==chess.PAWN and chess.square_rank(move.to_square) in (0,7): continue
                f.write(f'{packed(b):064x} {int(b.turn==chess.BLACK)} {rights(b):x} {int(b.ep_square is not None)} '
                        f'{b.ep_square or 0:x} {move.from_square:x} {move.to_square:x} {move.promotion or chess.QUEEN:x} '
                        f'{int(legal)} {packed(after):064x} {rights(after):x} {int(after.ep_square is not None)} {after.ep_square or 0:x}\n')
                count+=1
    print(f'Generated {count} move cases across {len(boards)} positions')

if __name__=='__main__':main()

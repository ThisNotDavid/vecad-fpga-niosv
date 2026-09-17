"""Package source and verified bitstream without caches or vendor dependencies."""
from pathlib import Path
import hashlib
import json
import zipfile
import argparse
from board_config import BOARDS
ROOT=Path(__file__).resolve().parents[1]
def main():
    p=argparse.ArgumentParser();p.add_argument('--board',choices=BOARDS,default='de10-lite');a=p.parse_args()
    cfg=BOARDS[a.board];project=cfg['project'];output=ROOT/cfg['output']
    manifest=json.loads((output/'build_manifest.json').read_text())
    for name,digest in manifest.items():
        if hashlib.sha256((ROOT/name).read_bytes()).hexdigest()!=digest:
            raise RuntimeError(f'{name} no longer matches the verified build')
    files=[ROOT/n for n in ['README.md','Start Chess.cmd','Program DE2-115.cmd','chess.qpf','chess.qsf','chess.sdc',
        'chess_de2_115.qpf','chess_de2_115.qsf','chess_de2_115.sdc','.gitignore']]
    for folder in ['rtl','assets','host','sim','tools','docs']:
        files.extend(p for p in (ROOT/folder).rglob('*') if p.is_file() and '__pycache__' not in p.parts)
    files.extend(output/n for n in [f'{project}.sof','build_manifest.json',f'{project}.fit.summary',f'{project}.sta.summary',f'{project}.pin'])
    out=ROOT/cfg['build']/('vecad_chess_de2_115_demo.zip' if a.board=='de2-115' else 'vecad_chess_demo.zip')
    with zipfile.ZipFile(out,'w',zipfile.ZIP_DEFLATED) as archive:
        for f in files:archive.write(f,f.relative_to(ROOT).as_posix())
    with zipfile.ZipFile(out) as archive:
        if archive.testzip() is not None:raise RuntimeError('Archive integrity check failed')
    print(f'Packaged {len(files)} files: {out}')
if __name__=='__main__':main()

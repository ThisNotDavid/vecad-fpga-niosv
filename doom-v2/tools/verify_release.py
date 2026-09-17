"""Read-only verification of every file recorded by freeze_v1.ps1."""
import argparse, hashlib, json
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('release',type=Path);a=p.parse_args()
manifest=json.loads((a.release/'manifest.json').read_text(encoding='utf-8-sig'))
for entry in manifest['files']:
    file=(a.release/entry['path']).resolve()
    if not file.is_relative_to(a.release.resolve()):raise RuntimeError('Unsafe manifest path')
    if file.stat().st_size!=entry['bytes'] or hashlib.sha256(file.read_bytes()).hexdigest()!=entry['sha256']:
        raise RuntimeError('Release file mismatch: '+entry['path'])
print('PASS release checksums:',len(manifest['files']),'files')

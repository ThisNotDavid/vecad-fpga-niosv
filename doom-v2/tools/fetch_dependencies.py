"""Fetch pinned engine and free IWAD data. Existing source checkouts are not reset."""
from pathlib import Path
import hashlib, subprocess, urllib.request, zipfile

ROOT = Path(__file__).resolve().parents[1]
COMMIT = 'dcb7a8dbc7a16ce3dda29382ac9aae9d77d21284'
URL = 'https://github.com/freedoom/freedoom/releases/download/v0.13.0/freedoom-0.13.0.zip'
SHA256 = '3f9b264f3e3ce503b4fb7f6bdcb1f419d93c7b546f4df3e874dd878db9688f59'

def main():
    source = ROOT / 'vendor/doomgeneric'
    if not source.exists():
        source.parent.mkdir(parents=True, exist_ok=True)
        subprocess.run(['git', 'clone', 'https://github.com/ozkl/doomgeneric.git', str(source)], check=True)
        subprocess.run(['git', '-C', str(source), 'checkout', '--detach', COMMIT], check=True)
    actual = subprocess.check_output(['git', '-C', str(source), 'rev-parse', 'HEAD'], text=True).strip()
    if actual != COMMIT:
        raise RuntimeError('Existing engine checkout differs from pinned revision; left unchanged')
    archive = ROOT / 'assets/freedoom-0.13.0.zip'
    archive.parent.mkdir(parents=True, exist_ok=True)
    if not archive.exists():
        urllib.request.urlretrieve(URL, archive)
    if hashlib.sha256(archive.read_bytes()).hexdigest() != SHA256:
        raise RuntimeError('Freedoom archive checksum mismatch')
    destination = ROOT / 'assets'
    if not (destination / 'freedoom-0.13.0/freedoom1.wad').exists():
        with zipfile.ZipFile(archive) as z:
            for member in z.infolist():
                resolved = (destination / member.filename).resolve()
                if not resolved.is_relative_to(destination.resolve()):
                    raise RuntimeError('Unsafe archive member')
            z.extractall(destination)
    print('Pinned engine and Freedoom 0.13.0 are available.')

if __name__ == '__main__':
    main()

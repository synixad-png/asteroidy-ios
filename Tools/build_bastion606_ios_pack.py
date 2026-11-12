#!/usr/bin/env python3
"""Reproducible lossless iOS import pack from the user's genuine PC v609 ZIP.

Run: python3 Tools/build_bastion606_ios_pack.py path/to/Asteroidy_v609_ZRODLA_Windows_SteamOS_BEZ_EXE_BEZ_HANGARU.zip BASTION_PC609.bastion
The ZIP is user-supplied, not an automatic network download or copied asset.
"""
from pathlib import Path
import gzip
import hashlib
import struct
import sys
import zipfile
import zlib

MESH = 'Shared/assets/bastion_glb/bastion.mesh.gz'
TEXTURE = 'Shared/assets/bastion_glb/bastion.base.jpg'
ORIGINAL = 'Shared/assets/bastion_glb/Bastion_original.glb'
EXPECTED = {
    'mesh': '5b9257d55d403a28ef37d370f95a1796e236b7bef34a695a313b1a48450baca6',
    'skin': '4882d508b527d1f13171cf72d732addbaf393681d37942378be5b39ef09fe65e',
    'glb': '402555221cf903e4d85ba615e8f0ea8646b216823041c5e71f4fe52fafdf8a75',
    'pack': 'd18d651aab74bebdb2215940c0774c8aa3f0aff9101c0b7122c336110b3f5e7c',
}
def sha256(data):
    return hashlib.sha256(data).hexdigest()

def main():
    if len(sys.argv)!=3:
        raise SystemExit('usage: build_bastion606_ios_pack.py PC609.zip BASTION_PC609.bastion')
    with zipfile.ZipFile(sys.argv[1]) as archive:
        assert archive.testzip() is None, 'PC609 ZIP CRC failed'
        mesh = gzip.decompress(archive.read(MESH))
        skin = archive.read(TEXTURE)
        glb = archive.read(ORIGINAL)
    assert sha256(mesh)==EXPECTED['mesh']
    assert sha256(skin)==EXPECTED['skin']
    assert sha256(glb)==EXPECTED['glb']
    assert struct.unpack_from('<II',mesh)==(6061,2)
    compressed=zlib.compress(mesh,9)
    pack=b'BST60901'+struct.pack('<III',len(mesh),len(compressed),len(skin))+compressed+skin
    assert sha256(pack)==EXPECTED['pack'], 'lossless PC609 source data unexpectedly changed'
    output=Path(sys.argv[2])
    output.parent.mkdir(parents=True,exist_ok=True)
    output.write_bytes(pack)
    print(f'PASS PC609 Bastion GLB 6061 geometry and JPEG, 2 source engines: {output} ({len(pack)} bytes), SHA256 {sha256(pack)}')

if __name__=='__main__':
    main()

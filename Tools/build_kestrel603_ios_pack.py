#!/usr/bin/env python3
"""Reproducibly package the genuine PC609 KESTREL v603 baked GLB.

Usage: python3 Tools/build_kestrel603_ios_pack.py PC609_SOURCES.zip KESTREL_PC609.kestrel
No geometry resampling, UV flipping, texture conversion or model substitution.
"""
from pathlib import Path
import gzip
import hashlib
import struct
import sys
import zipfile
import zlib

MESH='Shared/assets/kestrel603/kestrel603.mesh.gz'
TEXTURE='Shared/assets/kestrel603/kestrel603.base.jpg'
ORIGINAL='Shared/assets/kestrel603/Krestrel.glb'
EXPECTED={
    'mesh':'9652c1ab9db5bbe75135c005df9d32e4147c1393615d4b2822d4c295b93ae34a',
    'skin':'f6a717ad7a50497da5ee232e50dc156f946081cef98d9d258c30ce26008fcba6',
    'glb':'7a3d5328ab1e6dcb6368a04320c09a5426a2d194c387cc76dc50d8f018eb3053',
    'pack':'5d3598b655f362f284550261c4cbfe14775d1568885f1ce22b2baaa1c2c288a2',
}
def sha256(data):
    return hashlib.sha256(data).hexdigest()

def main():
    if len(sys.argv)!=3:
        raise SystemExit('usage: build_kestrel603_ios_pack.py PC609.zip KESTREL_PC609.kestrel')
    with zipfile.ZipFile(sys.argv[1]) as archive:
        assert archive.testzip() is None,'PC609 source ZIP CRC failed'
        mesh=gzip.decompress(archive.read(MESH))
        skin=archive.read(TEXTURE)
        glb=archive.read(ORIGINAL)
    assert sha256(mesh)==EXPECTED['mesh']
    assert sha256(skin)==EXPECTED['skin']
    assert sha256(glb)==EXPECTED['glb']
    assert len(mesh)==9_495_364
    magic,engines=struct.unpack_from('<II',mesh)
    assert (magic,engines)==(6031,2)
    float_count=struct.unpack_from('<I',mesh,32)[0]
    assert float_count//12==189_906 and float_count%12==0
    cpu_offset=36+float_count*4
    preview_count=struct.unpack_from('<I',mesh,cpu_offset)[0]
    assert preview_count==10_551
    assert len(mesh)==cpu_offset+4+preview_count*9*4
    compressed=zlib.compress(mesh,9)
    pack=b'KST60901'+struct.pack('<III',len(mesh),len(compressed),len(skin))+compressed+skin
    assert len(pack)==2_617_283
    assert sha256(pack)==EXPECTED['pack'],'Kestrel pack differs from original PC609 source'
    target=Path(sys.argv[2])
    target.parent.mkdir(parents=True,exist_ok=True)
    target.write_bytes(pack)
    print(f'PASS PC609 KESTREL603 source 6031, 189906 GPU vertices, 2 engine sockets, untouched JPEG. {len(pack)} bytes, SHA256 {sha256(pack)}')

if __name__=='__main__':
    main()

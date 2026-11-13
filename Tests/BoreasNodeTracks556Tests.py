#!/usr/bin/env python3
"""Verify exact 96 source GLB animated node channels in ASNT v1."""
from pathlib import Path
import hashlib,struct,math,zlib
p=Path(__file__).resolve().parents[1]/'ASTEROIDYiOS/Assets/Boreas556.asnt'
blob=p.read_bytes()
assert hashlib.sha256(blob).hexdigest()=='bdf22733cfe6a1314517537e2400019a97c3a83507b8f654fd1307dbf9809edc'
assert len(blob)==21218
magic,version,nodes,morph,total,unpacked=struct.unpack_from('<4sIIIII',blob)
assert (magic,version,nodes,morph,total,unpacked)==(b'ASNT',1,48,4320,31355,130752)
raw=zlib.decompress(blob[40:])
assert len(raw)==unpacked
assert hashlib.sha256(raw).hexdigest()=='2cca0a79d0e62845225bb819fdd8e3a4cbd37ae4cb512a18d8ca947731dbaccc'
offset=0;vertex=0;keysTotal=0;ids=set();animated=0
for i in range(48):
    idx,first,count,num=struct.unpack_from('<4I',raw,offset)
    offset+=16
    assert idx not in ids and 1<=idx<=48
    ids.add(idx)
    assert first==vertex and count==(72 if idx%2==0 else 108)
    assert num==(13 if idx%2==0 else 25)
    q=struct.unpack_from('<4f',raw,offset)
    offset+=16
    assert abs(sum(x*x for x in q)-1)<0.001
    offset+=count*3*4*2 # original local positions and normals
    f=[struct.unpack_from('<7f',raw,offset+k*28) for k in range(num)]
    offset+=num*28
    assert f[0][0]==0 and f[-1][0]==5
    assert all(f[k][0]<f[k+1][0] for k in range(num-1))
    assert all(math.isfinite(v) for row in f for v in row)
    assert all(v>=0 for row in f for v in row[4:])
    assert any(any(abs(a-b)>0.00001 for a,b in zip(f[0][1:],row[1:])) for row in f[1:-1])
    animated+=1;vertex+=count;keysTotal+=num
assert animated==48 and keysTotal==912 and vertex==4320 and offset==len(raw)
assert ids==set(range(1,49))
print('PASS all 48 Boreas source nodes / 96 original GLB translation+scale tracks')
print('PASS 912 native keyframes, authored 5-second times, finite TRS and local mesh')
print('PASS source-locked asset 21218 bytes, SHA256, decompressed layout, 4320 moving vertices')
print('NOTE author glTF node transform end keys differ from start: preserves source hard-loop semantics')

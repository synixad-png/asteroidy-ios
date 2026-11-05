#!/usr/bin/env python3
"""Source-to-export check against authentic v556 GLB morph accessors."""
import sys
from pathlib import Path
import zipfile
import numpy as np
sys.path.insert(0,str(Path(__file__).resolve().parents[1] / 'Tools'))
from export_boreas_morph import MEMBER, read_glb, accessor

source = Path(sys.argv[1]); output = Path(sys.argv[2]); raw = output.read_bytes()
assert raw[:4] == b'ASMO'
counts = np.frombuffer(raw, dtype='<u4', count=4, offset=4)
assert tuple(counts) == (1,27035,6,126)
n, k, f = 27035,6,126
p = 20
base = np.frombuffer(raw,dtype='<f4',count=n*3,offset=p).reshape(n,3);p+=n*3*4
deltas = np.frombuffer(raw,dtype='<f4',count=k*n*3,offset=p).reshape(k,n,3);p+=k*n*3*4
frames = np.frombuffer(raw,dtype='<f4',count=f*(k+1),offset=p).reshape(f,k+1)
with zipfile.ZipFile(source) as z: doc, binary = read_glb(z.read(MEMBER))
primitive = doc['meshes'][0]['primitives'][0]
assert np.array_equal(base,accessor(doc,binary,primitive['attributes']['POSITION']))
for i,t in enumerate(primitive['targets']):
    assert np.array_equal(deltas[i], accessor(doc,binary,t['POSITION']))
sample = doc['animations'][0]['samplers'][0]
assert np.array_equal(frames[:,0],accessor(doc,binary,sample['input']).reshape(-1))
assert np.array_equal(frames[:,1:],accessor(doc,binary,sample['output']).reshape(f,k))
assert np.linalg.norm(deltas)>0
print('PASS: all base positions, 6 authentic normalized morph deltas and 126 animation keyframes match v556 GLB')

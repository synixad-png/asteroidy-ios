#!/usr/bin/env python3
"""Preserve the actual v556 Boreas glTF node-0 morph animation in ASMO v1.

Data is LOCAL mesh coordinates, not baked into the static scene exporter.
ASMO v1: <4sIIII header (magic, version, vertexCount, targetCount, keyCount)
then base positions float32[vertex,3], target deltas float32[target,vertex,3],
then keyframes float32[key,1+targetCount] (time, weights).
"""
import json
import pathlib
import struct
import sys
import zipfile
import numpy as np
MEMBER = 'Shared/assets/planets/boreas_ferrofluid.glb'
TYPES = {'SCALAR': 1, 'VEC2': 2, 'VEC3': 3, 'VEC4': 4}

def read_glb(glb):
    if len(glb) < 20 or glb[:4] != b'glTF' or struct.unpack_from('<I', glb, 4)[0] != 2 or struct.unpack_from('<I', glb, 8)[0] != len(glb):
        raise ValueError('invalid GLB header')
    off, json_data, binary = 12, None, None
    while off + 8 <= len(glb):
        size, typ = struct.unpack_from('<I4s', glb, off); off += 8
        if off + size > len(glb): raise ValueError('invalid GLB chunk length')
        if typ == b'JSON': json_data = json.loads(glb[off:off + size])
        elif typ == b'BIN\x00': binary = memoryview(glb)[off:off + size]
        off += size
    if off != len(glb) or json_data is None or binary is None: raise ValueError('missing glTF JSON/BIN chunk')
    return json_data, binary

def accessor(doc, binary, index):
    a = doc['accessors'][index]
    if a.get('sparse') or a.get('componentType') not in (5126, 5120):
        raise ValueError('unsupported accessor (must be dense float32 or signed int8)')
    if a.get('componentType') == 5120 and not a.get('normalized'):
        raise ValueError('signed int8 target must be normalized')
    n, components = a['count'], TYPES[a['type']]
    view = doc['bufferViews'][a['bufferView']]
    element_size = 4 if a['componentType'] == 5126 else 1
    stride = view.get('byteStride', element_size * components)
    offset = view.get('byteOffset', 0) + a.get('byteOffset', 0)
    if stride < element_size * components or offset < 0 or offset + (n - 1) * stride + components * element_size > len(binary) or n <= 0:
        raise ValueError('accessor out of range')
    dtype = '<f4' if element_size == 4 else 'i1'
    if stride == components * element_size:
        result = np.frombuffer(binary, dtype=dtype, count=n * components, offset=offset).reshape(n, components).astype('<f4')
    else:
        fmt = '<' + ('f' if element_size == 4 else 'b') * components
        result = np.array([struct.unpack_from(fmt, binary, offset + i * stride) for i in range(n)], dtype='<f4')
    if element_size == 1: result = np.maximum(-1.0, result / 127.0)
    if not np.isfinite(result).all(): raise ValueError('nonfinite accessor values')
    return result

def export(zip_file, output):
    with zipfile.ZipFile(zip_file) as z: doc, binary = read_glb(z.read(MEMBER))
    node = doc['nodes'][0]
    if node.get('mesh') != 0: raise ValueError('Boreas node 0 mesh changed')
    prim = doc['meshes'][0]['primitives'][0]
    base = accessor(doc, binary, prim['attributes']['POSITION'])
    targets = [accessor(doc, binary, t['POSITION']) for t in prim['targets']]
    if not targets or any(t.shape != base.shape for t in targets): raise ValueError('invalid morph targets')
    anim = doc['animations'][0]
    channels = [c for c in anim['channels'] if c['target'] == {'node': 0, 'path': 'weights'}]
    if len(channels) != 1: raise ValueError('expected one weights channel for node 0')
    sample = anim['samplers'][channels[0]['sampler']]
    if sample['interpolation'] != 'LINEAR': raise ValueError('nonlinear weight animation')
    times = accessor(doc, binary, sample['input']).reshape(-1)
    weights = accessor(doc, binary, sample['output']).reshape(-1, len(targets))
    if len(times) != len(weights) or len(times) < 2 or np.any(np.diff(times) <= 0): raise ValueError('invalid key times')
    if abs(times[0]) > 1e-6 or times[-1] <= 0: raise ValueError('invalid animation duration')
    if any(abs(a-b)>1e-4 for a,b in zip(weights[0], weights[-1])):
        raise ValueError('not a seamless repeating morph animation')
    output.parent.mkdir(parents=True, exist_ok=True)
    with output.open('wb') as dst:
        dst.write(struct.pack('<4sIIII', b'ASMO', 1, len(base), len(targets), len(times)))
        dst.write(base.astype('<f4').tobytes())
        for target in targets: dst.write(target.astype('<f4').tobytes())
        dst.write(np.column_stack([times, weights]).astype('<f4').tobytes())
    return len(base), len(targets), len(times), float(times[-1])

if __name__ == '__main__':
    print('Boreas morph:', export(pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2])))

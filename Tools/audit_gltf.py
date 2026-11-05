#!/usr/bin/env python3
"""Read actual embedded GLB 2.0 JSON and report supported/unsupported features.
No guesswork: counts reflect the original glTF, not trimesh's flattened scene.
"""
import argparse
import json
import pathlib
import struct
import zipfile


def inspect_glb(blob):
    if len(blob) < 20 or blob[:4] != b'glTF':
        raise ValueError('Invalid GLB magic/header')
    version, length = struct.unpack_from('<II', blob, 4)
    if version != 2 or length != len(blob):
        raise ValueError('Unsupported version or incorrect GLB byte length')
    pos, document, bin_count = 12, None, 0
    while pos < len(blob):
        if pos + 8 > len(blob):
            raise ValueError('Truncated GLB chunk header')
        size, kind = struct.unpack_from('<I4s', blob, pos)
        pos += 8
        if size % 4 or pos + size > len(blob):
            raise ValueError('Unaligned/truncated GLB chunk')
        if kind == b'JSON':
            if document is not None:
                raise ValueError('Duplicate GLB JSON chunk')
            document = json.loads(blob[pos:pos+size].decode('utf-8').rstrip(' \x00'))
        elif kind == b'BIN\x00':
            bin_count += 1
        pos += size
    if document is None:
        raise ValueError('Missing GLB JSON')
    meshes = document.get('meshes', [])
    primitives = [p for m in meshes for p in m.get('primitives', [])]
    materials = document.get('materials', [])
    return {
        'asset_version': document.get('asset', {}).get('version'),
        'nodes': len(document.get('nodes', [])),
        'meshes': len(meshes),
        'primitives': len(primitives),
        'images': len(document.get('images', [])),
        'textures': len(document.get('textures', [])),
        'bin_chunks': bin_count,
        'primitives_with_texcoord0': sum('TEXCOORD_0' in p.get('attributes', {}) for p in primitives),
        'primitives_with_normals': sum('NORMAL' in p.get('attributes', {}) for p in primitives),
        'primitives_with_morph_targets': sum(bool(p.get('targets')) for p in primitives),
        'morph_target_count': sum(len(p.get('targets', [])) for p in primitives),
        'material_clearcoat_count': sum('KHR_materials_clearcoat' in m.get('extensions', {}) for m in materials),
        'material_basecolor_texture_count': sum('baseColorTexture' in m.get('pbrMetallicRoughness', {}) for m in materials),
        'material_normal_texture_count': sum('normalTexture' in m for m in materials),
        'animation_count': len(document.get('animations', [])),
        'extensions_used': document.get('extensionsUsed', []),
    }


def inspect_zip(zip_path, member):
    with zipfile.ZipFile(zip_path) as z:
        return inspect_glb(z.read(member))


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('zip_path', type=pathlib.Path)
    parser.add_argument('glb_member')
    args = parser.parse_args()
    print(json.dumps(inspect_zip(args.zip_path, args.glb_member), ensure_ascii=False, indent=2))

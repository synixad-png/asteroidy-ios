#!/usr/bin/env python3
"""Reproducible static glTF scene conversion from *only* ASTEROIDY v556 ZIP.
Applies scene node transforms, preserves triangle topology, and bakes material
baseColor/vertex-color, metallic/roughness and clearcoat into AS3D v3.
Does not include texture maps or animations.
"""
import io
import json
import pathlib
import struct
import sys
import zipfile
import numpy as np
import trimesh

MEMBER = 'Shared/assets/planets/boreas_ferrofluid.glb'

def export(zip_path: pathlib.Path, output: pathlib.Path):
    with zipfile.ZipFile(zip_path) as src:
        glb = src.read(MEMBER)
    json_size = struct.unpack_from('<I', glb, 12)[0]
    source_json = json.loads(glb[20:20 + json_size].decode('utf-8').rstrip(' \x00'))
    coats_by_name = {}
    for material in source_json.get('materials', []):
        coat_extension = material.get('extensions', {}).get('KHR_materials_clearcoat', {})
        coats_by_name[material.get('name')] = (
            float(coat_extension.get('clearcoatFactor', 0.0)),
            float(coat_extension.get('clearcoatRoughnessFactor', 0.04))
        )
    scene = trimesh.load(io.BytesIO(glb), file_type='glb', force='scene')
    parts = scene.dump(concatenate=False)  # transformations applied per node
    vertices = []
    indices = []
    for mesh in parts:
        if not isinstance(mesh, trimesh.Trimesh) or len(mesh.faces) == 0:
            continue
        v = np.asarray(mesh.vertices, dtype=np.float32)
        if not np.isfinite(v).all():
            raise ValueError('GLB contains non-finite vertex positions')
        rgba = np.asarray(mesh.visual.to_color().vertex_colors, dtype=np.float32) / 255.0
        if rgba.shape == (4,):
            rgba = np.broadcast_to(rgba, (len(v), 4)).copy()
        if rgba.shape != (len(v), 4):
            raise ValueError('Invalid material/vertex color length')
        mat = getattr(mesh.visual, 'material', None)
        metallic = float(getattr(mat, 'metallicFactor', 0.0) or 0.0)
        roughness = getattr(mat, 'roughnessFactor', 1.0)
        roughness = float(roughness if roughness is not None else 1.0)
        if not np.isfinite([metallic, roughness]).all():
            raise ValueError('Nonfinite PBR factors')
        metallic, roughness = np.clip(metallic,0,1), np.clip(roughness,0.04,1)
        # v556 Boreas uses KHR_materials_clearcoat. Preserve the material
        # extension rather than discarding its authored parameters.
        coat, coat_rough = coats_by_name.get(getattr(mat, 'name', None), (0.0, 0.04))
        coat, coat_rough = float(coat), float(coat_rough)
        if not np.isfinite([coat,coat_rough]).all():
            raise ValueError('Nonfinite clearcoat material')
        mr = np.tile(np.array([metallic,roughness,np.clip(coat,0,1),np.clip(coat_rough,0.04,1)],dtype=np.float32),(len(v),1))
        start = sum(len(x) for x in vertices)
        vertices.append(np.concatenate([v, rgba, mr], axis=1))
        faces = np.asarray(mesh.faces, dtype=np.int64)
        if faces.min() < 0 or faces.max() >= len(v):
            raise ValueError('GLB index out of bounds')
        indices.append((faces + start).astype('<u4').reshape(-1))
    if not vertices:
        raise ValueError('No triangle meshes in GLB')
    vertex = np.concatenate(vertices)
    index = np.concatenate(indices)
    xyz = vertex[:, :3]
    center = (xyz.min(axis=0) + xyz.max(axis=0)) * 0.5
    radius = float(np.linalg.norm(xyz - center, axis=1).max())
    if radius <= 0 or not np.isfinite(radius):
        raise ValueError('Invalid planet radius')
    # Fixed model-to-world transform; the diagnostic Sphere67's projection uses
    # a unit radius. Boreas visual only; not used as authoritative collision terrain.
    xyz[:] = (xyz - center) / radius
    packed = np.column_stack([xyz, np.ones(len(vertex)), vertex[:, 3:7], vertex[:, 7:11]]).astype('<f4')
    assert np.isfinite(packed).all()
    output.parent.mkdir(parents=True, exist_ok=True)
    with output.open('wb') as f:
        f.write(struct.pack('<4sIII', b'AS3D', 3, len(vertex), len(index)))
        f.write(packed.tobytes())
        f.write(index.tobytes())
    return len(parts), len(vertex), len(index) // 3, radius

if __name__ == '__main__':
    a = export(pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2]))
    print('Boreas556 GLB: nodes=%d vertices=%d triangles=%d original radius=%.4f' % a)

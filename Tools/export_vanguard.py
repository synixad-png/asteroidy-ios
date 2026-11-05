#!/usr/bin/env python3
"""Convert user-provided ASTEROIDY v556 ship GLB to a static Metal-friendly indexed mesh.
Source GLB is loaded only from the v556 source ZIP; no external asset substitution.
Vertex colors are approximations from glTF base textures/materials, not a PBR import.
"""
import io, zipfile, struct, pathlib, sys
import numpy as np
import trimesh
source = pathlib.Path(sys.argv[1]); output = pathlib.Path(sys.argv[2])
member = 'Shared/assets/vanguard431/Vanguard_551_SOURCE.glb'
with zipfile.ZipFile(source) as z:
    mesh = trimesh.load(io.BytesIO(z.read(member)), file_type='glb', force='scene').to_geometry()
verts = np.asarray(mesh.vertices, dtype=np.float32)
normals = np.asarray(mesh.vertex_normals, dtype=np.float32)
colors = np.asarray(mesh.visual.to_color().vertex_colors, dtype=np.float32) / 255.0
if colors.shape[0] != len(verts): raise ValueError('vertex color mismatch')
# GLB built Y-up with vehicle forward near +Z: project into XY gameplay plane.
xyz = np.stack((verts[:, 0], verts[:, 2], verts[:, 1]-0.18), axis=1) * 0.32
# Simple static directional illumination; the material is not physically based.
lighting = np.clip(0.60 + 0.40 * (normals @ np.array([0.35,0.75,0.55],dtype=np.float32)),0.3,1.0)
color = np.clip(colors[:, :3] * lighting[:, None] + 0.055, 0, 1)
packed = np.column_stack([xyz,np.ones(len(xyz),dtype=np.float32), color,np.ones(len(xyz),dtype=np.float32)]).astype('<f4')
faces = np.asarray(mesh.faces, dtype='<u4').reshape(-1)
with output.open('wb') as f:
    f.write(struct.pack('<4sIII',b'AS3D',1,len(verts),len(faces)))
    f.write(packed.tobytes());f.write(faces.tobytes())
print(f'AS3D exported: vertices={len(verts)} triangles={len(faces)//3} bytes={output.stat().st_size}')

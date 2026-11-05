#!/usr/bin/env python3
"""Generate validated v556 Boreas morph-to-static mesh binding. Requires numpy,trimesh."""
import io,json,struct,sys,zipfile
from pathlib import Path
import numpy as np,trimesh
SRC='Shared/assets/planets/boreas_ferrofluid.glb'
def export(zip_file, assets_dir):
    assets_dir=Path(assets_dir)
    with zipfile.ZipFile(zip_file) as z: data=z.read(SRC)
    scene=trimesh.load(io.BytesIO(data),file_type='glb',force='scene')
    parts=scene.dump(concatenate=False)
    verts=np.concatenate([np.asarray(p.vertices,dtype=np.float32) for p in parts]); center=(verts.min(axis=0)+verts.max(axis=0))*.5
    radius=float(np.linalg.norm(verts-center,axis=1).max())
    asmo=(assets_dir/'Boreas556.asmo').read_bytes()
    n=struct.unpack_from('<I',asmo,8)[0]
    base=np.frombuffer(asmo,dtype='<f4',offset=20,count=n*3).reshape(n,3)
    if len(parts[-1].vertices)!=n or np.max(abs(verts[-n:]-base))>1e-5: raise ValueError('morph primitive order/positions do not match static converter')
    mesh=(assets_dir/'Boreas556.as3d').read_bytes(); count=struct.unpack_from('<I',mesh,8)[0]
    static=np.frombuffer(mesh,dtype='<f4',offset=16,count=count*12).reshape(count,12)
    if count!=len(verts) or np.max(abs(static[-n:,:3]-(base-center)/radius))>1e-5: raise ValueError('AS3D position transform mismatch')
    result={'format':'BoreasMorphBinding556.v1','source':SRC,'firstVertex':count-n,'vertexCount':n,'staticVertexCount':count,'center':list(map(float,center)),'radius':radius,'verification':'Node0 mesh0 primitive0, identity node transform, matching static final vertices'}
    (assets_dir/'BoreasMorphBinding556.json').write_text(json.dumps(result,indent=2)+'\n')
    return result
if __name__=='__main__': print(export(sys.argv[1],sys.argv[2]))

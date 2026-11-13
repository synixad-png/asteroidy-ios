#!/usr/bin/env python3
"""Exact PC v568/v609 Boreas: extract the 96 original GLB node channels.

Uses only stdlib, four existing SHA-verified v568 GitHub archives, original
static AS3D and morph binding. Emits ASNT v1, no synthetic animation,
resampling, refitting or changes to the 26-sector campaign. In PC v609 this
GLB has SHA256 cdd64178... exactly as PC v568.
"""
from pathlib import Path
import argparse,hashlib,json,math,struct,sys,zipfile,zlib

SOURCE='PortingResources/v568/Shared/assets/planets/boreas_ferrofluid.glb'
SOURCE_PC='Shared/assets/planets/boreas_ferrofluid.glb'
SOURCE_SHA='cdd6417889452b60dd36fe9b2a4931259826852e613d84766b18165759ead759'
AS3D_SHA='0a18d88a734906811fc6421d79d68a56a2ae4bd7dd7a622fc89c46a4cd5fbf9b'
RAW_SHA='2cca0a79d0e62845225bb819fdd8e3a4cbd37ae4cb512a18d8ca947731dbaccc'
ASNT_SHA='bdf22733cfe6a1314517537e2400019a97c3a83507b8f654fd1307dbf9809edc'

def sha(data):
    return hashlib.sha256(data).hexdigest()

def source_glb(root,pc_zip=None):
    if pc_zip:
        with zipfile.ZipFile(pc_zip) as z:blob=z.read(SOURCE_PC)
    else:
        sys.path.insert(0,str(root/'Tools'))
        from stage_v568_resources import verify_archive_set
        archives,entries,manifest,_=verify_archive_set(root)
        try:
            if SOURCE not in entries or manifest.get(SOURCE)!=SOURCE_SHA:
                raise ValueError('Missing original Boreas from v568 SHA256 manifest')
            z,info=entries[SOURCE]
            blob=z.read(info)
        finally:
            for z in archives:z.close()
    if len(blob)!=2899120 or sha(blob)!=SOURCE_SHA:
        raise ValueError('Not the unchanged original PC v568/v609 Boreas GLB')
    return blob

def parse(blob):
    if len(blob)<20 or blob[:4]!=b'glTF' or struct.unpack_from('<II',blob,4)!=(2,len(blob)):
        raise ValueError('Invalid original glTF')
    cursor=12
    json_data=binary=None
    while cursor+8<=len(blob):
        length,typ=struct.unpack_from('<I4s',blob,cursor)
        cursor+=8
        if cursor+length>len(blob):raise ValueError('glTF chunk out of range')
        if typ==b'JSON':json_data=json.loads(blob[cursor:cursor+length])
        elif typ==b'BIN\x00':binary=memoryview(blob)[cursor:cursor+length]
        cursor+=length
    if cursor!=len(blob) or json_data is None or binary is None:
        raise ValueError('Missing glTF JSON/BIN')
    def accessor(index):
        item=json_data['accessors'][index]
        if item.get('sparse') or item['componentType']!=5126:
            raise ValueError('Non-float or sparse accessor')
        component={'SCALAR':1,'VEC3':3,'VEC4':4}[item['type']]
        view=json_data['bufferViews'][item['bufferView']]
        count=item['count'];stride=view.get('byteStride',component*4)
        start=view.get('byteOffset',0)+item.get('byteOffset',0)
        if count<1 or stride<component*4 or start<0 or start+(count-1)*stride+component*4>len(binary):
            raise ValueError('glTF accessor invalid bounds')
        vals=[struct.unpack_from('<'+'f'*component,binary,start+i*stride) for i in range(count)]
        if not all(math.isfinite(value) for item in vals for value in item):
            raise ValueError('Non-finite glTF float')
        return vals
    return json_data,accessor

def rotate(q,v):
    x,y,z,w=q
    vx,vy,vz=v
    ax=y*vz-z*vy;ay=z*vx-x*vz;az=x*vy-y*vx
    bx=y*az-z*ay;by=z*ax-x*az;bz=x*ay-y*ax
    return (vx+2*(w*ax+bx),vy+2*(w*ay+by),vz+2*(w*az+bz))

def export(root,destination,pc_zip=None):
    doc,acc=parse(source_glb(root,pc_zip))
    assert len(doc['nodes'])==49 and len(doc['meshes'])==3
    assert len(doc['animations'])==1
    anim=doc['animations'][0]
    assert len(anim['channels'])==len(anim['samplers'])==97
    tracks={}
    for item in anim['channels']:
        k=(item['target']['node'],item['target']['path'])
        assert k not in tracks
        samp=anim['samplers'][item['sampler']]
        assert samp.get('interpolation','LINEAR')=='LINEAR'
        tracks[k]=([x[0] for x in acc(samp['input'])],acc(samp['output']))
    assert set(tracks)=={(0,'weights')}|{(i,p) for i in range(1,49) for p in ('translation','scale')}
    assets=root/'ASTEROIDYiOS'/'Assets'
    static=(assets/'Boreas556.as3d').read_bytes()
    if sha(static)!=AS3D_SHA:raise ValueError('Original Boreas AS3D changed')
    bind=json.loads((assets/'BoreasMorphBinding556.json').read_text())
    assert bind['format']=='BoreasMorphBinding556.v1'
    assert bind['firstVertex']==4320 and bind['staticVertexCount']==31355
    center=[struct.unpack('<f',struct.pack('<f',x))[0] for x in bind['center']]
    radius=struct.unpack('<f',struct.pack('<f',bind['radius']))[0]
    assert radius>0 and math.isfinite(radius)
    magic,version,total,indexCount=struct.unpack_from('<4sIII',static)
    assert (magic,version,total)==(b'AS3D',3,31355)
    base=memoryview(static)[16:16+total*48]
    raw=bytearray();cursor=0;keyTotal=0
    # The already-verified v556 static exporter emitted nodes 48..1,
    # then node 0. Validate each local source GLB vertex against AS3D.
    for nodeId in range(48,0,-1):
        node=doc['nodes'][nodeId]
        meshId=node['mesh']
        assert meshId==(1 if nodeId%2 else 2)
        primitive=doc['meshes'][meshId]['primitives'][0]
        positions=acc(primitive['attributes']['POSITION'])
        normals=acc(primitive['attributes']['NORMAL'])
        count=len(positions)
        assert count==(108 if nodeId%2 else 72)==len(normals)
        times,trans=tracks[nodeId,'translation']
        times2,scales=tracks[nodeId,'scale']
        assert len(times)==len(times2)==len(trans)==len(scales) in (13,25)
        assert times==times2 and times[0]==0 and times[-1]==5
        assert all(times[k]>times[k-1] for k in range(1,len(times)))
        q=node['rotation']
        assert len(q)==4 and abs(sum(x*x for x in q)-1)<0.001
        for i,pos in enumerate(positions):
            v=rotate(q,[pos[k]*scales[0][k] for k in range(3)])
            expected=[(trans[0][k]+v[k]-center[k])/radius for k in range(3)]
            observed=struct.unpack_from('<3f',base,(cursor+i)*48)
            if max(abs(expected[k]-observed[k]) for k in range(3))>0.0001:
                raise ValueError('Boreas static/animated node mismatch: '+str(nodeId))
        raw+=struct.pack('<IIII4f',nodeId,cursor,count,len(times),*q)
        for v in positions:raw+=struct.pack('<3f',*v)
        for v in normals:raw+=struct.pack('<3f',*v)
        for t,p,size in zip(times,trans,scales):
            raw+=struct.pack('<7f',t,*p,*size)
        cursor+=count
        keyTotal+=len(times)
    assert cursor==4320 and keyTotal==912 and len(raw)==130752
    if sha(raw)!=RAW_SHA:raise ValueError('GLB 96 channels differ from original author keyframes')
    header=struct.pack('<4sIIIII3ff',b'ASNT',1,48,4320,total,len(raw),*center,radius)
    encoded=header+zlib.compress(bytes(raw),9)
    if sha(encoded)!=ASNT_SHA:
        raise ValueError('ASNT source-locked SHA256 changed')
    destination.parent.mkdir(parents=True,exist_ok=True)
    destination.write_bytes(encoded)
    print('PASS original Boreas 97 glTF channels: six morph targets + 48 translations + 48 scales')
    print('PASS 48 authentic GLB nodes, 912 keyframes, 5s loop, unchanged mesh normals')
    print('PASS ASNT',len(encoded),'bytes SHA256',sha(encoded))

if __name__=='__main__':
    p=argparse.ArgumentParser()
    p.add_argument('--root',type=Path,default=Path(__file__).resolve().parents[1])
    p.add_argument('--destination',type=Path,default=None)
    p.add_argument('--source-zip',type=Path,default=None)
    opt=p.parse_args()
    export(opt.root,opt.destination or
           opt.root/'ASTEROIDYiOS/Assets/Boreas556.asnt',opt.source_zip)

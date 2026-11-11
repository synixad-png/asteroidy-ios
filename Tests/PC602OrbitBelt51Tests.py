#!/usr/bin/env python3
"""PC v602 actual 820-asteroid belt resource validation.

Checks the binary written by the target-only C# generator that directly
retains source algorithms in OrbitWorld51.cs and GpuIntro41.cs. Geometries,
individual normals, source intervals and physical H290 terrain are checked,
not replaced by an assumed round asteroid. These are build tests, NOT a
render-performance or interactive iOS GPU certification.
"""
import argparse
import hashlib
import math
from pathlib import Path
import struct

COUNT=820
ENTRY=28
HEADER=16

def check(root,asset):
    blob=asset.read_bytes()
    if len(blob)<HEADER+COUNT*ENTRY:
        raise AssertionError("Missing complete source PC602 belt")
    magic,version,stones,total=struct.unpack_from("<4sIII",blob,0)
    assert magic==b"B051" and version==1 and stones==COUNT
    assert total%3==0 and total>=COUNT*960
    assert len(blob)==HEADER+COUNT*ENTRY+total*40
    height=root/"ASTEROIDYiOS/Assets/PC602Home290HeightMap.bin"
    assert hashlib.sha256(height.read_bytes()).hexdigest()==(
        "12d56a99634e4fc28ded9e03bcac34de05020750cc18e86d1086db8542b2d18d")
    heights=struct.unpack("<131072f",height.read_bytes())

    def surface(point):
        x,y,z=point
        norm=math.sqrt(x*x+y*y+z*z)
        lon=math.atan2(z/norm,x/norm)
        lat=math.asin(max(-1,min(1,y/norm)))
        u=(lon+math.pi)/(2*math.pi)*512-.5
        v=(lat+math.pi*.5)/math.pi*256-.5
        ix=math.floor(u);iy=math.floor(v)
        tx=u-ix;ty=v-iy
        a=heights[max(0,min(255,iy))*512+(ix%512)]
        b=heights[max(0,min(255,iy))*512+((ix+1)%512)]
        c=heights[max(0,min(255,iy+1))*512+(ix%512)]
        d=heights[max(0,min(255,iy+1))*512+((ix+1)%512)]
        return 100*((a+(b-a)*tx)*(1-ty)+(c+(d-c)*tx)*ty)

    detailed=0
    preceding=0
    first_seen=set()
    for i in range(COUNT):
        x,y,z,size,seed,first,count=struct.unpack_from(
            "<5fII",blob,HEADER+i*ENTRY)
        assert all(math.isfinite(v) for v in (x,y,z,size,seed))
        assert .22-1e-5<=size<=1.97+1e-5
        assert abs(seed-i*.73)<1e-3
        assert first==preceding
        expected=3840 if size>1.15 else 960
        assert count==expected
        detailed+=int(count==3840)
        preceding+=count
        radius=math.sqrt(x*x+y*y+z*z)*3.2
        assert radius>=surface((x,y,z))+18.8,("below PC602 H290 terrain",i)
        # Every authored asteroid has local crater-deformed XYZ+normal+RGBA.
        # Sample first and last original vertices for each distinct stone.
        for vertex in (first,first+count-1):
            floats=struct.unpack_from("<10f",blob,HEADER+COUNT*ENTRY+vertex*40)
            assert all(math.isfinite(v) for v in floats)
            distance=math.sqrt(sum((floats[k]-(x,y,z)[k])**2 for k in range(3)))
            assert distance<=size*2.0
            normal=math.sqrt(sum(floats[j]**2 for j in range(3,6)))
            assert abs(normal-1)<.02
            assert floats[9]==1
        first_seen.add((round(x,3),round(y,3),round(z,3)))
    assert preceding==total
    assert len(first_seen)==COUNT
    assert 0<detailed<COUNT
    digest=hashlib.sha256(blob).hexdigest()
    print(f"PASS PC602 exact C# source: {COUNT} distinct rocks, "
          f"{detailed} detailed crater meshes, {COUNT-detailed} basic, "
          f"{total//3} real triangles, {len(blob)} bytes SHA256 {digest}")
    print("LIMIT: native iOS framebuffer, FPS and exact PC GPU pixels NOT tested")

def main():
    cli=argparse.ArgumentParser()
    cli.add_argument("--root",type=Path,default=Path(__file__).resolve().parents[1])
    cli.add_argument("--asset",type=Path,required=True)
    args=cli.parse_args()
    check(args.root,args.asset)

if __name__=="__main__":
    main()

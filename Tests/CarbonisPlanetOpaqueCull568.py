#!/usr/bin/env python3
"""Audit original C279 planet *all triangles* before enabling safe Metal culling.

Requires exact source binary assets staged by prepare_v568_carbonis_sector01.
This proves winding and vertex alpha from the actual shipped planet.
It does NOT claim any measured iPhone FPS gain.
"""
import hashlib,struct,pathlib
root=pathlib.Path(__file__).resolve().parents[1]
assets=root/"ASTEROIDYiOS"/"Assets"
v=(assets/"Sector01CarbonisVertices.bin").read_bytes()
i=(assets/"Sector01CarbonisIndices.bin").read_bytes()
assert len(v)==137067*48
assert len(i)==810747*4
assert hashlib.sha256(v).hexdigest()=="b35318d059b9c4f180d03f36e52a6c4eea1225a484e339d3f117e5df9d7634bd"
assert hashlib.sha256(i).hexdigest()=="e542a65a0ddf0767d982b573da037becea7872cc8a6e0d5d1e1851cd90730bef"
xyz=[struct.unpack_from("<fff",v,j*48) for j in range(137067)]
alpha=[struct.unpack_from("<f",v,j*48+9*4)[0] for j in range(137067)]
assert min(alpha)==max(alpha)==1.,("vertex alpha",min(alpha),max(alpha))
front=back=flat=0
for j in range(0,810747,3):
    a,b,c=struct.unpack_from("<III",i,j*4)
    A,B,C=xyz[a],xyz[b],xyz[c]
    ex,ey,ez=(B[k]-A[k] for k in range(3))
    fx,fy,fz=(C[k]-A[k] for k in range(3))
    nx=ey*fz-ez*fy
    ny=ez*fx-ex*fz
    nz=ex*fy-ey*fx
    px=(A[0]+B[0]+C[0])/3
    py=(A[1]+B[1]+C[1])/3
    pz=(A[2]+B[2]+C[2])/3
    d=nx*px+ny*py+nz*pz
    if d>0:front+=1
    elif d<0:back+=1
    else:flat+=1
assert front==270249 and back==0 and flat==0,(front,back,flat)
swift=(root/"ASTEROIDYiOS"/"Sector01CarbonisPreview568.swift").read_text()
metal=(root/"ASTEROIDYiOS"/"Sector01Carbonis568.metal").read_text()
assert "view.isOpaque=gameplay" in swift
assert "spec.colorAttachments[0].isBlendingEnabled=false" in swift
assert "encoder.setFrontFacing(.counterClockwise)" in swift
assert "encoder.setCullMode(.back)" in swift
assert "encoder.setCullMode(.none)" in swift
assert "let gameplay=gameSession != nil" in swift
assert "albedo.a*=sourceCombined.a;" in metal
base=(assets/"Sector01CarbonisBase.dat").read_bytes()
assert base.startswith(bytes.fromhex("ffd8")), "source RGB base texture must be JPEG (no alpha)"
print(f"PASS original C279: {front} outward faces / {back} inward / {flat} degenerate; {len(alpha)} opaque vertices, source JPEG")
print("PASS source PC opaque C279 Metal backface state and transparent preview isolation")
print("LIMIT: source winding/alpha proof; GPU FPS and visual output require physical iOS validation")

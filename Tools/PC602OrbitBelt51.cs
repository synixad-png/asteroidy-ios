// ASTEROIDY PC v602 — targeted original-source bake of NEW HOME's orbital belt.
// Preserved algorithms from Windows/src/OrbitWorld51.cs (BuildBelt51),
// Intro41.cs (IntroScene41), NewHome290.cs (HeightAt),
// Orbit50.cs (Rotate), PlanetLife52.cs (Basis),
// GpuIntro41.cs (IntroStone, StoneNormal56, StoneFace, StoneSubdivide56,
// PrepareIntroBelt). No synthetic asteroid, no PC602 archive transfer.
//
// The only new part is offline binary serialization for Metal. The game
// retains all 820 original asteroid meshes and original collision locations.
// Build with dotnet on a host; iOS only loads the finished immutable asset.
using System;
using System.Collections.Generic;
using System.IO;
using IP=Asteroidy.IntroScene41.P;

namespace Asteroidy {
internal static class Game {
 public const float PI=(float)Math.PI,IntroDuration=16;
}
internal static class IntroScene41 {
 internal struct P {
  public float X,Y,Z;
  public P(float x,float y,float z){X=x;Y=y;Z=z;}
  public static P operator +(P a,P b){return new P(a.X+b.X,a.Y+b.Y,a.Z+b.Z);}
  public static P operator -(P a,P b){return new P(a.X-b.X,a.Y-b.Y,a.Z-b.Z);}
  public static P operator *(P a,float b){return new P(a.X*b,a.Y*b,a.Z*b);}
  public float Length{get{return (float)Math.Sqrt(X*X+Y*Y+Z*Z);}}
  public P Unit{get{return this*(1/Math.Max(.00001f,Length));}}
 }
 internal static float Dot(P a,P b){return a.X*b.X+a.Y*b.Y+a.Z*b.Z;}
 internal static P Cross(P a,P b){return new P(a.Y*b.Z-a.Z*b.Y,a.Z*b.X-a.X*b.Z,a.X*b.Y-a.Y*b.X);}
 internal static float Smooth(float t){t=Math.Max(0,Math.Min(1,t));return t*t*(3-2*t);}
 internal static readonly P PlanetCenter=new P(-38,4,-56);
 internal const float ApproachStart=8.4f,ArrivalTime=15.2f,ArrivalRadius=34;
 internal static readonly P ArrivalNormal=new P(.62f,.18f,.765f).Unit;
 internal static readonly P ArrivalPoint=PlanetCenter+ArrivalNormal*ArrivalRadius;
 static P OrbitalShip(float t){return new P(0,(float)Math.Sin(t*.6f)*.25f,42-6.7f*t);}
 internal static P Ship(float t){
  t=Math.Max(0,Math.Min(Game.IntroDuration,t));if(t<=ApproachStart)return OrbitalShip(t);
  float u=Math.Min(1,(t-ApproachStart)/(ArrivalTime-ApproachStart)),v=1-u;
  P a=OrbitalShip(ApproachStart),b=a+new P(0,.15f,-6.7f*(ArrivalTime-ApproachStart)/3),c=ArrivalPoint+ArrivalNormal*5;
  return a*(v*v*v)+b*(3*v*v*u)+c*(3*v*u*u)+ArrivalPoint*(u*u*u);
 }
 internal static P Forward(float t){if(t>=ArrivalTime-.02f)return ArrivalNormal*-1;return (Ship(t+.02f)-Ship(Math.Max(0,t-.02f))).Unit;}
 internal static P Camera(float t){
  float phase=Smooth(t/ApproachStart),yaw=phase*(float)Math.PI*2,distance=13+7*(float)Math.Sin(phase*Math.PI),height=5+7*(float)Math.Sin(phase*Math.PI);
  P orbit=new P((float)Math.Sin(yaw)*distance,height,(float)Math.Cos(yaw)*distance);
  float blend=Smooth((t-ApproachStart)/2.4f);P up=(Ship(t)-PlanetCenter).Unit,follow=Forward(t)*-11+up*4;
  return Ship(t)+orbit*(1-blend)+follow*blend;
 }
}
internal static class NewHome290 {
 internal const int Width=512,Height=256;
 internal static readonly bool Enabled=true;
 static float[] HeightMap=Array.Empty<float>();
 internal static void Load(string path){
  byte[] b=File.ReadAllBytes(path);
  if(b.Length!=Width*Height*4)throw new InvalidDataException("Wrong H290 512x256 physical height map");
  HeightMap=new float[Width*Height];
  using(BinaryReader rd=new BinaryReader(new MemoryStream(b)))
   for(int i=0;i<HeightMap.Length;i++){
    float h=rd.ReadSingle();if(float.IsNaN(h)||float.IsInfinity(h))throw new InvalidDataException("Nonfinite original H290 height");
    HeightMap[i]=h;
   }
 }
 internal static float HeightAt(IP d){
  if(HeightMap.Length!=Width*Height)throw new InvalidOperationException("Original H290 terrain is not staged");
  IP n=d.Unit;float lon=(float)Math.Atan2(n.Z,n.X),lat=(float)Math.Asin(Math.Max(-1,Math.Min(1,n.Y)));
  float u=(lon+(float)Math.PI)/(float)(2*Math.PI)*Width-.5f;
  float v=(lat+(float)Math.PI*.5f)/(float)Math.PI*Height-.5f;
  int x=(int)Math.Floor(u),y=(int)Math.Floor(v);float tx=u-x,ty=v-y;
  int x0=((x%Width)+Width)%Width,x1=(x0+1)%Width,y0=Math.Max(0,Math.Min(Height-1,y)),y1=Math.Max(0,Math.Min(Height-1,y+1));
  float h00=HeightMap[y0*Width+x0],h10=HeightMap[y0*Width+x1],h01=HeightMap[y1*Width+x0],h11=HeightMap[y1*Width+x1];
  return 100f*((h00+(h10-h00)*tx)*(1-ty)+(h01+(h11-h01)*tx)*ty);
 }
 internal static float Surface(IP p){return HeightAt(p);}
 internal static IP LegacyBeaconDirection290(){return new IP((float)Math.Cos(Game.PI/8),0,(float)Math.Sin(Game.PI/8));}
 internal static IP WreckPosition(){IP n=LegacyBeaconDirection290(),t=IntroScene41.Cross(new IP(0,1,0),n).Unit,b=IntroScene41.Cross(n,t).Unit;IP d=(n*142-t*126+b*12).Unit;return d*(Surface(d)+15f);}
}
internal static class PlanetLife52 {
 internal static void Basis(IP n,out IP r,out IP f){r=IntroScene41.Cross(n,Math.Abs(n.Y)<.9f?new IP(0,1,0):new IP(1,0,0)).Unit;f=IntroScene41.Cross(r,n).Unit;}
}
internal static class OrbitWorld50 {
 internal struct Stone51 {internal IP Center;internal float Size,Seed;}
 internal static readonly Stone51[] Belt51=BuildBelt51();
 internal static IP Rotate(IP v,IP axis,float angle){float c=(float)Math.Cos(angle),s=(float)Math.Sin(angle);return v*c+IntroScene41.Cross(axis,v)*s+axis*(IntroScene41.Dot(axis,v)*(1-c));}
 // The following matches the PC602 BuildBelt51 source's operation order.
 static Stone51[] BuildBelt51(){Stone51[] belt=new Stone51[820];Random random=new Random(4109);for(int i=0;i<820;i++){float angle=i*2.399963f,radius=52+(float)random.NextDouble()*16,y=((float)random.NextDouble()-.5f)*8;IP origin=new IP((float)Math.Cos(angle)*radius,y,(float)Math.Sin(angle)*radius),world=origin+IntroScene41.PlanetCenter;if(Math.Abs(world.X)<3.6f&&Math.Abs(world.Y)<3&&world.Z>-42&&world.Z<24)origin.Y+=(world.Y<0?-1:1)*6;float size=.22f+(float)Math.Pow(random.NextDouble(),3)*1.75f,seed=i*.73f;
  for(int attempt=0;attempt<4;attempt++){bool blocked=false;for(int sample=0;sample<=(int)(Game.IntroDuration*5);sample++){float t=sample*.2f;IP eye=IntroScene41.Camera(t),target=IntroScene41.Ship(t),line=target-eye,point=origin+IntroScene41.PlanetCenter-eye;float projection=Math.Max(0,Math.Min(1,IntroScene41.Dot(point,line)/Math.Max(.001f,IntroScene41.Dot(line,line))));if((point-line*projection).Length<size+3.2f){blocked=true;break;}}if(!blocked)break;origin.Y+=(i%2==0?1:-1)*(8+size);}
  if(NewHome290.Enabled){
   IP direction=origin.Unit;
   float flightRadius=NewHome290.Surface(direction)+19f+(float)random.NextDouble()*7f;
   origin=direction*(flightRadius/3.2f);
   IP dock=NewHome290.WreckPosition();float exclusion=52f+size*3.2f*1.38f+1.2f;
   for(int tries=0;tries<15&&(origin*3.2f-dock).Length<exclusion;tries++){
    direction=Rotate(direction,new IP(0,1,0),(i%2==0?1f:-1f)*.42f).Unit;
    origin=direction*((NewHome290.Surface(direction)+19f+(float)random.NextDouble()*7f)/3.2f);
   }
  }
  belt[i]=new Stone51{Center=origin,Size=size,Seed=seed};}return belt;}
}
internal sealed class GpuRenderer {
 // Source GpuIntro41.cs: complete original 12-vertex icosahedron and 20 faces.
 static readonly IP[] introIco={new IP(-1,1.618f,0),new IP(1,1.618f,0),new IP(-1,-1.618f,0),new IP(1,-1.618f,0),new IP(0,-1,1.618f),new IP(0,1,1.618f),new IP(0,-1,-1.618f),new IP(0,1,-1.618f),new IP(1.618f,0,-1),new IP(1.618f,0,1),new IP(-1.618f,0,-1),new IP(-1.618f,0,1)};
 static readonly int[] introFaces={0,11,5,0,5,1,0,1,7,0,7,10,0,10,11,1,5,9,5,11,4,11,10,2,10,7,6,7,1,8,3,9,4,3,4,2,3,2,6,3,6,8,3,8,9,4,9,5,2,4,11,6,2,10,8,6,7,9,8,1};
 static IP IntroStone(IP p,float seed){p=p.Unit;float r=.91f+.065f*(float)Math.Sin(p.X*4+p.Y*3+p.Z*5+seed)+.022f*(float)Math.Sin(p.X*21-p.Y*18+p.Z*16+seed*2);for(int i=0;i<3;i++){IP crater=new IP((float)Math.Sin(seed*1.3f+i*4),(float)Math.Cos(seed*.7f+i*7),(float)Math.Sin(seed*.9f-i*3)).Unit;float q=(p-crater).Length;r-=.095f*(float)Math.Exp(-q*q/(.04f+i*.014f));}return new IP(p.X*r*(.8f+.25f*(float)Math.Sin(seed)),p.Y*r,p.Z*r*(1.1f+.2f*(float)Math.Cos(seed)));}
 static IP StoneNormal56(IP p,float seed){p=p.Unit;IP r,f;PlanetLife52.Basis(p,out r,out f);IP n=IntroScene41.Cross(IntroStone((p+r*.001f).Unit,seed)-IntroStone((p-r*.001f).Unit,seed),IntroStone((p+f*.001f).Unit,seed)-IntroStone((p-f*.001f).Unit,seed)).Unit;return IntroScene41.Dot(n,p)<0?n*-1:n;}
 static void StoneFace(List<float> data,IP a,IP b,IP c,IP origin,float size,float seed){IP pa=a.Unit,pb=b.Unit,pc=c.Unit;a=IntroStone(pa,seed)*size;b=IntroStone(pb,seed)*size;c=IntroStone(pc,seed)*size;if(IntroScene41.Dot(IntroScene41.Cross(b-a,c-a),a)<0){IP swap=b;b=c;c=swap;swap=pb;pb=pc;pc=swap;}IP[] vertices={a,b,c},directions={pa,pb,pc};for(int i=0;i<3;i++){IP v=vertices[i]+origin,n=StoneNormal56(directions[i],seed);float shade=.70f+.08f*(float)Math.Sin(seed+directions[i].X*13+directions[i].Z*11),red=shade*.58f,green=shade*.62f,blue=shade*.69f;if((int)seed%7==0){red*=1.3f;green*=1.13f;blue*=.9f;}data.AddRange(new[]{v.X,v.Y,v.Z,n.X,n.Y,n.Z,red,green,blue,1});}}
 static void StoneSubdivide56(List<float> data,IP a,IP b,IP c,IP origin,float size,float seed,int depth){if(depth==0){StoneFace(data,a,b,c,origin,size,seed);return;}IP ab=(a+b).Unit,bc=(b+c).Unit,ca=(c+a).Unit;StoneSubdivide56(data,a,ab,ca,origin,size,seed,depth-1);StoneSubdivide56(data,ab,b,bc,origin,size,seed,depth-1);StoneSubdivide56(data,ca,bc,c,origin,size,seed,depth-1);StoneSubdivide56(data,ab,bc,ca,origin,size,seed,depth-1);}
 public readonly int[] Starts=new int[820],Counts=new int[820];
 public float[] PrepareIntroBelt(){List<float> data=new List<float>(7872000);for(int i=0;i<OrbitWorld50.Belt51.Length;i++){OrbitWorld50.Stone51 stone=OrbitWorld50.Belt51[i];IP origin=stone.Center;float size=stone.Size,seed=stone.Seed;
  Starts[i]=data.Count/10;
  for(int f=0;f<introFaces.Length;f+=3)StoneSubdivide56(data,introIco[introFaces[f]].Unit,introIco[introFaces[f+1]].Unit,introIco[introFaces[f+2]].Unit,origin,size,seed,size>1.15f?3:2);
  Counts[i]=data.Count/10-Starts[i];
 }return data.ToArray();}
}
internal static class Program {
 static int Main(string[] args) {
  try {
   if(args.Length!=2)throw new ArgumentException("Usage: pc602belt H290HeightMap.bin output/PC602OrbitBelt51.bin");
   NewHome290.Load(args[0]);
   OrbitWorld50.Stone51[] rocks=OrbitWorld50.Belt51;
   if(rocks.Length!=820)throw new InvalidDataException("Original PC602 Belt51 must contain 820 stones");
   GpuRenderer renderer=new GpuRenderer();
   float[] triangles=renderer.PrepareIntroBelt();
   if(triangles.Length%30!=0 || renderer.Starts[0]!=0)throw new InvalidDataException("Original IntroBelt triangle stream is damaged");
   int expected=0;
   for(int i=0;i<rocks.Length;i++){
    int size=rocks[i].Size>1.15f?3840:960;
    if(renderer.Starts[i]!=expected || renderer.Counts[i]!=size)throw new InvalidDataException("PC602 source LOD/stone offset mismatch at "+i);
    IP n=rocks[i].Center.Unit,world=rocks[i].Center*3.2f;
    if(world.Length<NewHome290.Surface(n)+18.9f)throw new InvalidDataException("Stone below original H290 terrain: "+i);
    expected+=size;
   }
   if(expected!=triangles.Length/10)throw new InvalidDataException("Original 820-rock vertex total mismatch");
   Directory.CreateDirectory(Path.GetDirectoryName(Path.GetFullPath(args[1]))!);
   using(FileStream stream=File.Create(args[1]))using(BinaryWriter writer=new BinaryWriter(stream)){
    writer.Write(new byte[]{(byte)'B',(byte)'0',(byte)'5',(byte)'1'});
    writer.Write((uint)1);writer.Write((uint)rocks.Length);writer.Write((uint)expected);
    for(int i=0;i<rocks.Length;i++){
     var s=rocks[i];writer.Write(s.Center.X);writer.Write(s.Center.Y);writer.Write(s.Center.Z);
     writer.Write(s.Size);writer.Write(s.Seed);
     writer.Write((uint)renderer.Starts[i]);writer.Write((uint)renderer.Counts[i]);
    }
    foreach(float v in triangles){if(float.IsNaN(v)||float.IsInfinity(v))throw new InvalidDataException("Nonfinite original stone vertex");writer.Write(v);}
   }
   Console.WriteLine("PASS PC602 BuildBelt51 and PrepareIntroBelt: "+rocks.Length+" original stones, "+expected+" vertices, "+expected/3+" triangles, "+new FileInfo(args[1]).Length+" bytes");
   return 0;
  }catch(Exception error){Console.Error.WriteLine("FAIL PC602 original belt bake: "+error);return 1;}
 }
}
}
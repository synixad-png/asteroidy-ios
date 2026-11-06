// Wrapper around the byte-exact source v568 music and sound generators.
// All actual DSP and composition logic remains in original C# files.
using System;
using System.IO;
namespace Asteroidy {
 public enum Weapon {Pulse,Twin,Scatter,Rail,Swarm}
 public static class AudioRender568Harness {
  public static int Main(string[] args) {
   try {
    if(args.Length!=3)throw new ArgumentException("Usage: AudioRender568Harness music|sfx|intro index[:variant] output.pcm");
    short[] pcm=null;
    if(args[0]=="music") {
     int index=int.Parse(args[1]);
     if(index<0||index>=MusicSynth.Count)throw new ArgumentOutOfRangeException("index");
     pcm=MusicSynth.Generate(index,null);
    } else if(args[0]=="intro") {
     if(args[1]!="15")throw new ArgumentOutOfRangeException("intro");
     pcm=IntroMusic43.Generate();
    } else if(args[0]=="sfx") {
     string[] parts=args[1].Split(':');
     int code=int.Parse(parts[0]),variant=parts.Length>1?int.Parse(parts[1]):0;
     if(!((code>=10&&code<=14)||(code>=20&&code<=22)||code==30||
          (code>=40&&code<=45)||code==60))
       throw new ArgumentOutOfRangeException("code");
     pcm=CombatSound.Get(code,variant);
    } else throw new ArgumentException("Unknown original generator mode");
    if(pcm==null||pcm.Length<2||pcm.Length%2!=0)
     throw new InvalidDataException("Invalid original stereo PCM");
    using(FileStream stream=File.Create(args[2])) {
     byte[] bytes=new byte[pcm.Length*2];
     Buffer.BlockCopy(pcm,0,bytes,0,bytes.Length);
     stream.Write(bytes,0,bytes.Length);
    }
    Console.WriteLine("ORIGINAL v568 "+args[0]+" "+args[1]+" frames="+(pcm.Length/2));
    return 0;
   }catch(Exception ex){Console.Error.WriteLine("SOURCE AUDIO FAILED: "+ex);return 1;}
  }
 }
}

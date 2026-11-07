#!/usr/bin/env python3
"""Original Explosion524: never skip any nonzero-opacity raymarch sample.
Pure numerical test; does NOT establish GPU FPS or visual parity.
"""
import math, random
rng=random.Random(524)
checks=skipped=0
for scale in (.45,1.,1.7):
    for spread in (.4,1.25,2.):
        for age in (.05,.32,.8,1.9,3.6,4.7):
            bound=min(5.1,max(2.6,1.9+age*1.55*spread))*scale
            for steps in (22,32,48):
                step=2.*bound/steps
                for _ in range(500):
                    angle=rng.random()*2*math.pi
                    radius=math.sqrt(rng.random())*bound*1.02
                    x,y=radius*math.cos(angle),radius*math.sin(angle)
                    r2=x*x+y*y
                    if r2>bound*bound:continue
                    active=bound*.98
                    reach2=active*active-r2
                    first=last=0
                    if reach2>0:
                        reach=math.sqrt(reach2)
                        first=max(0,min(steps,math.ceil((bound-reach)/step-.5)))
                        last=max(0,min(steps,math.ceil((bound+reach)/step-.5)))
                    assert 0<=first<=last<=steps
                    for i in range(steps):
                        z=-bound+(i+.5)*step
                        nonzero=math.sqrt(r2+z*z)<active
                        retained=first<=i<last
                        assert retained or not nonzero,("opaque sample discarded",scale,spread,age,steps,i)
                        checks+=1
                        if not retained:skipped+=1
assert skipped>0
print(f"PASS: {checks:,} Explosion524 samples checked; {skipped:,} mathematically zero-opacity samples omitted")

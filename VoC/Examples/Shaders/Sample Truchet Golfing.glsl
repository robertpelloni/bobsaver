#version 420

// original https://www.shadertoy.com/view/ll2fz1

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define v vec3
#define r(i) length(v(0,length(t[i].xy)-1.,s[i]))-.1

void main(void)
{
    vec2 U = gl_FragCoord.xy;
    v p = time*v(.5),
         F = vec3(resolution.xy,1.0),
         d = normalize(v((U.xy * 2.0 - F.xy) / F.y,1)),s,q,f;
    float D = 0.,
          l,
          Q;
    for (int i = 0; i < 99; i++) {
        
        F = floor(p*.5);
        f =    v(sign(sin(F.y*F.z+F.zx)+.01),1);
        s = (mod(p,2.)-1.)*f;
        
        v a = v(1,-1,0);
        mat3 t = mat3(
            s.yzx+a.xxz,
            s.zxy-a.xxz,
            s+a
        );

        l = min(min(r(0),r(1)),r(2));
        
        //position of the nearest torus
        q = t[ int(r(1)<=l) + 2*int(r(2)<=l) ];
        
        p += d*l;
        D += l;
    }
    //coloring the truchet in a rainbow pattern
    vec4 O;
    O.xyz = (sin(((mod(F.x+F.y,2.)*2.-1.)
            *(atan(q.x,q.y)*6.+atan(q.z,length(q.xy)-1.)*f.x*f.y)*1.9+time)
            *2.1+v(1,2,3))*0.5+0.5)
            /(D*D*.02+1.);
    glFragColor = O;
}

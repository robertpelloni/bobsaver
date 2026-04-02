#version 420

// original https://www.shadertoy.com/view/4c2fzD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// 2024?8?27?
// ??????
// Learn from:Elsio's Split the cube - https://www.shadertoy.com/view/lf23DG

// 6.86 9.05
#define time (time-10.+25.3)

vec3 dir, rd, id3;

vec3 hash33(vec3 p3)
{// form Dave_Hoskins:  www.shadertoy.com/view/4djSRW
        p3 = fract(p3*vec3(.1031, .1030,.0973));
        p3 += dot(p3, p3.yxz+33.33);
        return fract((p3.xxy+p3.yxx)*p3.zyx);
}

// Code Collation:
// https://beautifier.io/
float splitCube(vec3 p) {
        vec3 mn = vec3(-20), md = vec3(0), mx = vec3(20);
        vec3 mxi = mx, mni = mn;
        vec3 dlt, cnt, edg, boxm, f3;
        float dcub, dbox, f, i, N = 3.;
        id3 = step(md, p);
        for (i = 0.; i < N; i++) {
                id3 = id3 * 2. + step(md, p);
                mx = mix(md, mx, step(md, p));
                mn = mix(mn, md, step(md, p));
                f3 = hash33(mx + mn);
                f3 = .2 + .6 * f3;
                md = mix(mn, mx, f3);
        }
        edg = step(-.01, mni - mn) + step(-.01, mx - mxi);
        cnt = (mx + mn) * .5;
        cnt *= 1. + edg * (1.5 + .7*hash33(id3+1.)) * smoothstep(-.5, .5, sin(time+hash33(id3+2.)));
        dcub = length(max(abs(p - cnt) - ((mx - mn) * .5 - .6), 0.)) - .6;
        boxm = abs(p - mix(mn, mx, step(0., rd))) / abs(rd);
        dbox = min(boxm.x, min(boxm.y, boxm.z));
        return min(dcub, dbox + .01);
}

float map(vec3 p)
{
        float t = time*.1 ;
        mat2 rot = mat2(cos(t),-sin(t),sin(t),cos(t));
        rd = dir;
        p.yz *=rot;rd.yz *=rot;
        p.xz *=rot;rd.xz *=rot;
        return splitCube(p);
}

void main(void)
{
        vec4 O;
        vec2 v = gl_FragCoord.xy;
        vec4 bk=O = vec4(.7,.8,1,1)*.7;
        vec2 R = resolution.xy,
             u = 1. * (v+v+.1 - R) / R.y,      // ????
             m = 1. * (mouse*resolution.xy.xy*2. - R) / R.y;// ????
        vec3 o = vec3(0, 0, -80),               // ????
             r = normalize(vec3(u, 2)),        // ??
             e = vec3(0, 1e-3, 0),             // ??
             p,n,                                // ???
             s = normalize(vec3(-1,2,-3));     // ??
        dir=r;
        float d,t,f,g,c;
        for(int i;i<1256 && t < 220.;i++)
        {
                p = o + r * t;
                d = map(p);
                if(d<.01)
                {
                        O *= 0.;
                        n = normalize(vec3(map(p+e.yxx),map(p+e),map(p+e.xxy))-d);
                        f = .5 + .5 * dot(n, s);
                        g = max(dot(n,s),0.);
                        c = 1. + pow(f, 200.)-f*.3; // 665.352.6.542.9958.8.63
                        O += c*hash33(id3).rgbb;
                        O = mix(bk,O,   //smoothstep(-20.,20., -(t+o.z))       );  //    
                                             smoothstep(-20.,20.,exp(-.1*(t+o.z - 20. ))));
                        break;
                }
                t += d ;
        }
        
        glFragColor = O;
}
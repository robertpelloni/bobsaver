#version 420

// original https://www.shadertoy.com/view/dtSyDd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Can someone fix my crappy code :((

int AA = 10, FR = 2, MS = 128;

float PR = .001,

PI = 4. * atan(1.);

#define S smoothstep
#define N normalize
#define F(i, x) for(int i = 0; i < x; i++)

#define t (time + .35 * (p.y + 1.) * (-sin(time) + 1.) - .7)

vec3 gC = vec3(1, .4, .2);

mat2 Rot(float a)
{
    float s = sin(a), c = cos(a);
    return mat2(c, -s, s, c);
}

#define sabs(p) sqrt((p) * (p) + 1e-5)
#define smax(a,b) (a + b + sabs(a - b)) * .5

#define f(v) d = smax(d, dot(p, v));
#define sym float d = 0.; p = sabs(p); f(n) f(n.yzx) f(n.zxy)

float Dod(vec3 p)
{
    vec3 n = vec3(.851, .525, 0);
    
    sym
    
    return d;
}

float Ico(vec3 p)
{
    vec3 n = vec3(.357, .934, 0);
    
    sym f(vec3(.577))
    
    return d;
}

#define prg S(0., 1., S(0., 1., S(-1., 1., cos(t / 2. - PI / 4.))))

float map(vec3 p, float time)
{
    p.xz *= Rot(t + .8 * cos(t) + 1.);
    
    return mix(Dod(p), Ico(p), prg) - 1.;
}

float march1(vec3 ro, vec3 rd, float time)
{
    float b  = dot(ro, rd),
          h  = b * b - dot(ro, ro) + 1.59,
          dO = -b - sqrt(h);
          
    if(h < 0.) return 10.;
    
    F(i, MS)
    {
        vec3 p = ro + rd * dO;
        float dS = map(p, time);
        dO += dS;
        
        if (dO > 10. || abs(dS) < PR) break;
    }
    
    return dO;
}

vec3 glow(vec3 ro, vec3 rd, float time)
{
    float dO = 0.;
    vec3 glow = vec3(0);
    
    F(i, MS)
    {
        vec3 p = ro + rd * dO;
        float dS = map(p, time);
        
        dO += dS;
         
        glow += gC * max(1. - pow(dS / 3. + fract(dS * 4375.8545312), 5.), 0.) * .03;
        
        if (dO > dot(-ro, rd) && dS > 2.) break;
    }
    
    return glow;
}

float march2(vec3 ro, vec3 rd, float time)
{
    float b  = dot(ro, rd),
          dO = -b + sqrt(b * b - dot(ro, ro) + 1.59);
    
    F(i, MS)
    {
        vec3 p = ro + rd * dO;
        float dS = map(p, time);
        dO -= dS;
        if(dO > 2.6 || abs(dS) < PR) break;
    }
    
    return dO;
}

vec3 normal(vec3 p, float time)
{
    vec3 n = vec3(0);
    
    F(i, 4)
    {
        vec3 e = mod(vec3((i + 3) / 2, i / 2, i), 2.) - .5;
        n += e * map(p + PR * e, time);
    }
    
    return N(n);
}

vec3 bg(vec3 rd, float time)
{
    rd /= -rd.x;
    float y = abs(mod(20. * rd.y + 7. * time / PI + 1.4 * cos(time) - 1., 2.) - 1.);
    return gC / (1e2 * y * y + 1.) + gC * smoothstep(.1, .05, y);
}

vec3 spec(float w)
{
    vec3 col =   clamp(vec3(max((440. - w) / 60., (w - 510.) / 70.),
                            min((w - 440.) / 50., (645. - w) / 65.),
                            (510. - w) / 20.), 0., 1.)
                            
               * (.3 + .7 * min(min((w - 380.) / 40., (780. - w) / 80.), 1.));
    
    col = pow(col, vec3(.8));
    
    return col;
}

void main(void)
{
    vec4 O = vec4(0);
    vec2 I = gl_FragCoord.xy;

    if (1.5 * abs(I.x - .5 * resolution.x) > resolution.y) return;
    
    vec3 c1 = vec3(0), c2 = vec3(0);
    
    F(i, AA)
    {
        vec3 p3 = fract(vec3(I + fract(time), i) * vec3(.1031, .103, .0973));
             p3 += dot(p3, p3.yxz + 33.33);
             p3 = fract((p3.xxy + p3.yxx) * p3.zyx);
        
        p3.xz = (float(i) + p3.xz) / float(AA);
        
        float time = mod(time + p3.x / 48. + .5, 4.) * PI;
        
        vec2 uv = (I + p3.yz - .5 - .5 * resolution.xy) / resolution.y;
        
        vec3 ro = vec3(6, 0, 0),
             rd = N(vec3(-2, uv.yx)),
             col = vec3(0);
        
        float d = march1(ro, rd, time);

        if(d > 9.) col = bg(rd, time) + glow(ro, rd, time);
        else
        {
            vec3 p = ro + rd * d,
                 n = normal(p, time),
                 r = reflect(rd, n),
                 fl = gC * (sin(9. * r.x * r.y * r.z) * .5 + .5) + bg(r, time),
                 fr;
            
            F(j, FR)
            {
                vec4 p4  = fract(vec4(I + fract(time), i * 99, j * 99) * vec4(.1031, .103, .0973, .1099));
                     p4 += dot(p4, p4.wzxy + 33.33);
            
                float ran = fract((p4.x + p4.y) * (p4.z + p4.w));
                ran *= ran + 33.33;
                ran *= 2. * ran;
                
                ran = (float(i * FR + j) + fract(ran)) / float(AA * FR);
                
                float IOR = 1.4 + .1 * ran;
                      
                vec3 rdIn = refract(rd, n, 1./IOR);

                vec3 pExit = p + rdIn * march2(p, rdIn, time),
                     nExit = -normal(pExit, time),

                     rdOut = refract(rdIn, nExit, IOR);
                
                if(length(rdOut) < .001) rdOut = reflect(rdIn, nExit);
                
                #define m(p) mod(p / 4. + time / PI + .5, 2.)

                float fade = min(8. * m(p) * m(pExit), 4.).y;
                
                fr   =   spec(ran * 400. + 380.) * bg(rdOut, time)
                     * ((prg > .5) ? vec3(5, 1, 1) : vec3(1, 1, 5));
                     
                col += mix(fr, fl, .96 * pow(1. + dot(rd, n), 5.) + .04) * fade / vec3(FR);
            }
        }
        
        col *= 1. - dot(uv, uv) / .7;
        col *= mix(.25, 1., sin(time) * .5 + .5);
        
        F(i, 3) col[i] = (col[i] < .0031308) ? col[i] * 12.92 : pow(col[i], .42) * 1.055 - .055;
        
        c1 += col / vec3(AA);
        c2 += (1. - exp(-col * 2.)) / vec3(AA);
    }
    
    O.xyz = mix(1. - exp(-c1 * 2.), c2, exp(-c1));

    glFragColor = O;
}
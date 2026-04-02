#version 420

// original https://www.shadertoy.com/view/ldSBDK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define TAU 6.28318530718

#define FAR 25.
#define ITER 128
#define QUA .001
#define NORK 5e-4

#define REF 0.56
#define RITER 16
#define RRFB .001

#define BRG 0.83

float map(vec3 p)
{
    float d = FAR;
    d = min(d, length(p-vec3(0.75,vec2(.0)))-1.);    // center ball
    d = min(d, 5. - abs(p.x));                        // left & right wall
    d = min(d, 3. - abs(p.y - 2.));                    // floor & ceil
    d = min(d, 5. - abs(p.z));                        // front & back wall
    return d;
}

vec3 normal(vec3 p, float k)
{
    vec2 e = vec2(.0,k);
    return normalize(vec3(
        map(p) - map(p - e.yxx),
        map(p) - map(p - e.xyx),
        map(p) - map(p - e.xxy)
    ));
}

float tracer(vec3 ro, vec3 rd)
{    
    float t = .0, d;
    for(int i=0; i < ITER; i++){        
        d = map(ro + rd*t);
        if (d < QUA*t || t > FAR) break;
        t += d;
    } 
    return t + QUA;
}

float hard_shadow(vec3 sp, vec3 lp, int iter)
{   
    vec3 p, ld = normalize(sp - lp);

    float t = .0;
    for(int i = 0; i < iter; i++)
    {
        p = lp + ld * t;
        float m = map(p);
        if (m < .0 || t > FAR) break;
        t += m;
    }

    return max(1. - distance(p, sp), 0.);
}

vec3 color(vec3 sp, vec3 sn)
{   
    vec3 lp = vec3(-1, 1, -2);
    vec3 ld = normalize(lp - sp);
    
    float diff = max(dot(sn,ld),0.);
    float shd = hard_shadow(sp, lp, 30);
    
    vec3 col = (sn.xyz+1.)/2.;
    return col * diff * shd;
}

void main(void)
{   
    vec2 uv = (2.*gl_FragCoord.xy-resolution.xy)/resolution.y;
    if(fract((time-5.)/20.) < 0.5) uv.x *= -1.0;
    
    vec3 ro = vec3(abs(10. - mod(time-5.,20.)) - 5., .0, -3.);
    vec3 rd = normalize(vec3(uv,2.));
    
    float t = tracer(ro,rd);
    vec3 sp = ro + rd*t;
    vec3 sn = normal(sp,NORK);
    
    vec3 col = color(sp, sn);
    
    for(int i=0; i<RITER; i++)
    {
        if(t > FAR) break;
            
        rd = normalize(reflect(rd, sn));
        ro = sp + rd * RRFB;
        
        t = tracer(ro, rd);
        
        sp = ro + rd * (t - RRFB);
        sn = normal(sp,NORK);
    
        col += color(sp, sn) * pow(REF, float(i) + 1.);
    }
    
    glFragColor = BRG * vec4(col,1.);
}

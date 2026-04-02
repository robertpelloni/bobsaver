#version 420

// original https://www.shadertoy.com/view/XslBzM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define TAU 6.28318530718

#define FAR 21.
#define ITER 128
#define QUA .001
#define NORK 5e-4

float map(vec3 p)
{
    p.xy += vec2(cos(p.z),sin(p.z))/2.;
    vec3 cen = round(p);
    vec3 v = abs(cen-p);
    return max(v.x,v.y)-.09;
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
    return t;
}

void main(void)
{
    vec2 uv = (2.*gl_FragCoord.xy-resolution.xy)/resolution.y;
    
    float ang = atan(uv.x,uv.y) - time/8.;
    uv = vec2(cos(ang),sin(ang))*length(uv);

    vec3 ro = vec3(vec2(.5),time);
    vec3 rd = normalize(vec3(uv,2));
    
    float t = tracer(ro,rd);
    vec3 sp = ro + rd*t;
    
    vec3 sn = normal(sp,NORK);
    vec3 ld = normalize(-rd);
    float a = dot(sn,ld);
    
    vec3 col = (sn+1.)/2.; //texture(iChannel0,sn).rgb;
    col *= (3.+a)/4.;
    col -= pow(t/FAR,2.);
    
    glFragColor = vec4(col,1.);
}

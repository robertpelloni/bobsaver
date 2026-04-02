#version 420

// original https://www.shadertoy.com/view/3lc3Rr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//Thanks IQ for distance functions
//http://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm

//Thanks BigWings for KIFS Fractals explained
//https://www.youtube.com/watch?v=il_Qg9AqQkE&t=

#define pi 3.14159
#define SURF_DIST .001
#define MAX_DIST 100.
#define MAX_STEPS 100

const float eps = 0.001;

mat2 rot(float a)
{
    return mat2(cos(a), -sin(a), sin(a), cos(a));
}

float aaStep(float edge, float gradient)
{
    float halfPix = fwidth(gradient) / 2.0;
    float low = edge - halfPix;
    float hi  = edge + halfPix;
    return clamp((gradient - low) / (hi - low), 0.0, 1.0);
}

vec2 KIFS(vec2 uv)
{
    uv *= 1.5;
    vec2 mouse = mouse*resolution.xy.xy/resolution.xy;
    vec3 col = vec3(0.);
    uv.x = abs(uv.x);
    float angle = 5./6. * pi;
    uv.y += tan(angle)*0.5;
    vec2 norm = vec2(sin(angle), cos(angle));
    float dist = dot(uv - vec2(0.5, 0.0), norm);
    uv -= norm * 2. * max(dist, 0.);
    angle = 2./3. * pi * (1. - mouse.y);
    norm = vec2(sin(angle), cos(angle));
    uv.x += 0.5;
    float scale = 1.0;
    for(int i = 0; i < 4; i++){
        scale *= 3.;
        uv *= 3.;
        uv.x -= 1.5;
        uv.x = abs(uv.x);
        uv.x -= .5;
        uv *= rot(time*0.2 + mouse.x*10.);
        uv -= norm * 2. * min(dot(uv, norm), 0.);
    }
    uv/= scale;
    return uv;
}

float sdBox( vec3 p, vec3 b )
{
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float sdf(vec3 p)
{
    p *= 0.5;
    float f = max(min(abs(KIFS(p.xy).y), 1.0), sdBox(p, vec3(0.5, 0.5, 0.05))) - 0.0005;
    return min(f, -p.z + 0.1);
}

vec2 march(vec3 ro, vec3 rd)
{
    float t = 0.0 , d = MAX_DIST, it = 0.;
    for (int i = 0; i < MAX_STEPS; i++)
    {
        d = sdf(ro+t*rd);
         t += d;
        if(abs(d) < SURF_DIST || t > MAX_DIST) break;
        it += 1.0;
    }
    return vec2(t, it/float(MAX_STEPS));
}

float getShadow(vec3 p, vec3 n, vec3 ld)
{
    p += 2. * eps * n;
    float t = 0.0, d = MAX_DIST;
    for(int i = 0; i < MAX_STEPS; i++)
    {
        d = sdf(p + t * ld);
        t += d;
        if (abs(d) < eps || t > 3.0) break;
    }
    return t <= 3.0 ? 0.05 : 1.0;
}

vec3 getNorm(vec3 p)
{
    vec2 e = vec2(eps, 0);
    return normalize(vec3(sdf(p+e.xyy)-sdf(p-e.xyy), sdf(p+e.yxy)-sdf(p-e.yxy), sdf(p+e.yyx)-sdf(p-e.yyx)));
}

vec3 light(vec3 p)
{
    vec3 col = vec3(0.0);
    vec3 ld = normalize(vec3(-1.0,1.0,-5.0));
    vec3 n = getNorm(p);
    float diff = max(dot(n, ld), 0.);
    diff *= getShadow(p, n, ld);
    col += diff;
    return col;
}

vec3 bg(vec2 uv)
{
    vec2 ouv = uv;
       uv.x += sin(ouv.y*40. + 3.5*time) * 0.01;
    uv.y += sin(ouv.x*40. + 5.5*time) * 0.005;
    uv = KIFS(uv);
    float l = abs(sin(uv.y*10.+time));
    l = pow(0.1/l, 2.0);
    return vec3(l) * vec3(0.07,0.25, 1.0);
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - 0.5 * resolution.xy) / resolution.y;
    vec3 rd = normalize(vec3(uv, 1.0));
    vec3 ro = vec3(0., 0., -1.5);
    vec3 col;
    vec2 m = march(ro, rd);
    vec3 p = ro + rd * m.x;
    col += p.z > 0.1 ? (light(p) * pow(0.01/(abs(KIFS(p.xy*0.5))).y, 2.2)) * vec3(0.2, 0.4, 2.3) + light(p) * 0.1 : light(p);
    col += (m.y*m.y*m.y*m.y*m.y)*vec3(0.2, 0.4, 2.3)*100.;
    glFragColor = vec4(col,1.0);
}

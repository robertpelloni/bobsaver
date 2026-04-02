#version 420

// original https://www.shadertoy.com/view/wdcGzf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define SURF_DIST .001
#define MAX_DIST 100.
#define MAX_STEPS 100

mat2x2 rot(float a) 
{
    return mat2x2(cos(a),sin(a),-sin(a),cos(a));
}

float sdf(vec3 p)
{
    return min(1.,p.y);
}

float march(vec3 ro, vec3 rd) 
{
    float dS, dO;
    vec3 p;
    for(int i=0; i < MAX_STEPS; i++)
    {
        p = ro + dO * rd;
        dS = sdf(p);
        dO += dS;
        if(dS < SURF_DIST || dO > MAX_DIST) break;
    }
    return dO;
}

vec3 normal(vec3 p)
{
    float d = sdf(p);
    vec2 e = vec2(0.01, 0.0);
    vec3 n = d - vec3(sdf(p - e.xyy), sdf(p - e.yxy), sdf(p - e.yyx));
    return normalize(n);
}

float light(vec3 p, vec3 ro)
{
    vec3 lp = ro + vec3(0.0, 0.0, -0.1);
    vec3 l = normalize(lp - p);
    vec3 n = normal(p);
    return dot(n, l);
}

float hash(vec2 p)
{
    return fract(sin(dot(p, vec2(27.754, 78.4476))) * 47125.3567);
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - 0.5*resolution.xy)/resolution.y;
    vec3 rd = normalize(vec3(uv, 1.0));
    rd.zy *= rot(0.4);
    vec3 ro = vec3(0.5, 5.5, time * 3.5);
    vec3 col;
    float m = march(ro, rd);
    float im = 1.0 / m;
    vec3 p = ro + rd * m;
    col += light(p, ro);
    p.x += sin(time*3. + p.z*0.3)*0.5;
    vec2 fluv = floor(p.xz);
    vec2 fruv = fract(p.xz) - 0.5;
    float t = fruv.y - fruv.x;
    if (hash(fluv) > 0.5) {t = fruv.y + fruv.x;}
    col += smoothstep(0.1,0.0,vec3(abs(t))) + smoothstep(0.9,1.0,vec3(abs(t)));
    col *= 0.5 + 0.5*cos(-time*2.+p.zzz*0.15+vec3(0,2,4));
    col *= im*im*100.;
    glFragColor = vec4(col, 1.0);
}

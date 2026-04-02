#version 420

// original https://www.shadertoy.com/view/stjSWz

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Fork of "Gyroid Sphere" by Kamoshika. https://shadertoy.com/view/sljXz1
// 2021-07-28 12:18:10

// https://twitter.com/kamoshika_vrc/status/1418594024475136002

#define D(p) abs(dot(sin(p), cos(p.yzx)))

vec2 mp = vec2(0);

mat3 rotate3D(float angle, vec3 axis){
    vec3 a = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float r = 1.0 - c;
    return mat3(
        a.x * a.x * r + c,
        a.y * a.x * r + a.z * s,
        a.z * a.x * r - a.y * s,
        a.x * a.y * r - a.z * s,
        a.y * a.y * r + c,
        a.z * a.y * r + a.x * s,
        a.x * a.z * r + a.y * s,
        a.y * a.z * r - a.x * s,
        a.z * a.z * r + c
    );
}

vec3 hsv(float h, float s, float v) {
    vec4 a = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(vec3(h) + a.xyz) * 6.0 - vec3(a.w));
    return v * mix(vec3(a.x), clamp(p - vec3(a.x), 0.0, 1.0), s);
}

float map(vec3 p) {
    float d = length(p) - 1.8 + mp.x;
    p *= 10.;
    d = max(d, (D(p) - .08) / 10.);
    p *= 10.;
    d = max(d, (D(p) - .4 - 1.1*mp.y) / 100.);
    return d;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy * 2. - resolution.xy) /min(resolution.x, resolution.y);
         mp = vec2(0.0);//(mouse*resolution.xy.xy / resolution.xy);
    vec3 col = vec3(0);
    
    mat3 cRot = rotate3D(time*0.1, vec3(1, 1, 1));
    vec3 cPos = vec3(0, 0, 2) * cRot;
    vec3 cDir = normalize(-cPos);
    vec3 cSide = normalize(cross(cDir, vec3(0, 1, 0) * cRot));
    vec3 cUp = normalize(cross(cSide, cDir));
    vec3 ray = normalize(uv.x*cSide + uv.y*cUp + cDir*2.);
    
    vec3 rPos = cPos;
    float d = 0.;
    float c = 0.;
    for(int i=0; i<99; i++) {
        d = map(rPos);
        if(d < 1e-4) {
            break;
        }
        rPos += ray * d * .6;
        c++;
    }
    col += hsv(.3 - length(rPos), .7, 20./c);
    
    glFragColor = vec4(col, 1.0);
}

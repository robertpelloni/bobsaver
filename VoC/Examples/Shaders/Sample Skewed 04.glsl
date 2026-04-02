#version 420

// original https://www.shadertoy.com/view/ttSXWR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float z = 1.;
const float complexity =10.;
const float density = .09; // 0-1

const float PI = atan(1.)*4.;

vec4 hash42(vec2 p)
{
    p+=1e4;
    vec4 p4 = fract(vec4(p.xyxy) * vec4(.1031, .1030, .0973, .1099));
    p4 += dot(p4, p4.wzxy+33.33);
    return fract((p4.xxyz+p4.yzzw)*p4.zywx);
}

mat2 rot2D(float r){
    return mat2(cos(r), sin(r), -sin(r), cos(r));
}

#define q(x,p) (floor((x)/(p))*(p))

void main(void)
{
    vec2 C = gl_FragCoord.xy;
    vec4 o = glFragColor;

    vec2 R = resolution.xy;
    vec2 uv = C/R.xy;
    vec2 N = uv-.5;
    float t = time*.1;
    t+=1e2;
    uv.x *= R.x/R.y;
    uv *= rot2D(t*.2);
    uv *= z;
    uv+=t;
    o = vec4(1);
    float s = 1.;
    float f = .95;

    for (float i = 1.;i <= complexity; ++ i) {
        vec2 c = floor(uv+i);
        vec4 h = hash42(c);
        vec2 p = fract(uv+i)-t*s;
        s = -s;
        p *= rot2D(h.y);
        uv += p * h.z;
        uv *= 1.1;
        c = floor(uv+i);
        h = hash42(c);
        if (h.w < density) {
            o *= h;
        }
    }
    o *= 1.-dot(N,N);

    glFragColor = o;
}


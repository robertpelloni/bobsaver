#version 420

// original https://www.shadertoy.com/view/3tSXDV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const vec2 z = vec2(1);
const float complexity =5.;
const float density = .6;

const float PI = atan(1.)*4.;

vec4 hash42(vec2 p)
{
    p+=1e2;
    vec4 p4 = fract(vec4(p.xyxy) * vec4(.1031, .1030, .0973, .1099));
    p4 += dot(p4, p4.wzxy+33.33);
    return fract((p4.xxyz+p4.yzzw)*p4.zywx);
}

#define q(x,p) (floor((x)/(p))*(p))

mat2 rot2D(float r){
    return mat2(cos(r), sin(r), -sin(r), cos(r));
}

void main(void)
{
    vec2 C = gl_FragCoord.xy;
    vec4 o = glFragColor;

    vec2 R = resolution.xy;
    vec2 uv = C/R.xy;
    vec2 N = uv;
    float t = time*.05+1e2;
    uv.x *= R.x/R.y;

    uv *= rot2D(PI/4.);
    uv *= z;
    
    vec4 c = hash42(floor(uv));
    float s = sign(c.z-.5);
    s = 1.;
    float d = 1.;
    
    for (float i = 1.;i <= complexity; ++ i) {
        vec4 c = hash42(floor(uv));
        vec2 p = fract(uv)*2.-.1;
        uv +=(t+c.xy);
        
        if (i < 4.) {
            o = c*p.x;
        }
        else if (c.w > density) {
            o *= c*p.x;
        }
        uv *= 2.;
    }
    o=pow(o,o-o+.3);
    N-=.5;
    o*=1.-dot(N,N);

    glFragColor = o;
}


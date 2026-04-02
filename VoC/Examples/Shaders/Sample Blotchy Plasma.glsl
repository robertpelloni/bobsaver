#version 420

// original https://www.shadertoy.com/view/cl3GD8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float gStep = .2;
vec4 hash42(vec2 p)
{
    vec4 p4 = fract(vec4(p.xyxy) * vec4(.1031, .1030, .0973, .1099));
    p4 += dot(p4, p4.wzxy+33.33);
    return fract((p4.xxyz+p4.yzzw)*p4.zywx);
}

void main(void) //WARNING - variables void ( out vec4 o, in vec2 gl_FragCoord.xy ) need changing to glFragColor and gl_gl_FragCoord.xy
{
    vec4 o=vec4(0.0);
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    vec2 uvo = uv-.5;
    uv.x *= resolution.x / resolution.y;
    uv *= 24.;
    uv += sin((vec2(uv.y, -uv.x)+time*.5)*4.)*.15;
    uv += 14.+time;
    
    vec2 id = floor(uv);
    float s = 1.;
    
    for (float i = 0.;i<1.;i+=gStep)
    {
        s = -s;
        uv += sin((vec2(uv.y,s*uv.x) + time*.4));
        uv *= (i+.25);
        
        id = floor(uv);
        vec2 p =  uv-id;
        vec4 h = hash42(id);
        
        float d = .707-length((p-.5));
        float d2 = step(mix(.15,.45,h.x), d);
        float db = max(abs(p.x-.5),abs(p.y-.5));
        o = h* max(d2,pow(max(0.,.5-db), .5));
    }
    o *= 1.-dot(uvo,1.5*uvo);
    glFragColor=o;
}
#version 420

// original https://www.shadertoy.com/view/DsGSWV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec4 hash42(vec2 p)
{
    vec4 p4 = fract(vec4(p.xyxy) * vec4(.1031, .1030, .0973, .1099));
    p4 += dot(p4, p4.wzxy+33.33);
    return fract((p4.xxyz+p4.yzzw)*p4.zywx);
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    vec2 uvo = uv-.5;
    uv.x *= resolution.x / resolution.y;
    vec4 o = vec4(0);
    uv += 12.; // seed
    
    float a = 1.;

    for (float i = 0.;i<1.;i += .1)
    {
        vec2 id = floor(uv);
        vec2 p = abs(uv-id-.5); // cell position, offset to center, abs
        float d = 1.-max(p.x,p.y)*2.; // dist to edge
        vec4 h = hash42(id);
        a *= d;
        if (i-.25 > h.x) break;
        o = mix(h,o,d); //o = h; works too but layering is prettier imo

        vec4 hx = hash42(vec2(3.33,4.44)*id.x); // col hash, lazy
        vec4 hy = hash42(vec2(3.33,4.44)*id.y); // row hash, lazy
        hx = sign(hx-.5);
        hy = sign(hy-.5);
        uv.x += uv.y * hx.x* i; // skew
        uv.y += uv.x * hy.x * i;
        uv += hx.xy*hy.xy*time*.04;
   
        uv *= 2.;
    }

    o *= pow(a,.1);
    o *= 1.-dot(uvo,1.5*uvo);
    o *= 1.5;
    glFragColor = o;
}
#version 420

// original https://www.shadertoy.com/view/wljXWV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// trippy

mat2 rot(float a)
{
    float c = cos(a);
    float s = sin(a);
    return mat2(c, s, -s, c);
}
vec3 fx(float time, vec2 uv)
{
    //float time = time;
    vec2 f = vec2(0.3);
    vec3 c = vec3(1.2,1.0,1.0);
    float light = 0.1;
    
    for (float x = 1.1; x < 10.0; x += 1.0)
    {
        uv *= rot(x*200.0+sin(time*0.08));
        
        f = vec2(cos(cos(time*0.6+x + uv.x * x) - uv.y * dot(vec2(x + uv.y), vec2(sin(x), cos(x)))));
        light += (0.04 / distance(uv, f)) - (0.01 * distance(vec2((cos(time*0.3 + uv.y))), vec2(uv)));
        
        c.y += sin(x+time+abs(uv.y))*0.3;
        if (c.y<0.8)
            c.y = 0.8;
        light-=x*0.001 + c.y*0.001;
        
    }
    c *= light;
    c.x += (sin(time*2.4)*0.1);
    return c;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - 0.5 * resolution.xy) / resolution.y;
    vec3 ccc = fx(time*0.76,uv);
    uv.y = dot(uv,uv);
    uv.x = dot(uv,uv*2.0)*0.25;
    glFragColor = vec4(ccc*fx(time,uv),1.0);
}

#version 420

// original https://www.shadertoy.com/view/MtXGW8

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;

out vec4 glFragColor;
 
vec2 rotate(in vec2 p, in float t)
{
    return p*cos(-t)+vec2(p.y, -p.x)*sin(-t);
}

float sdTorus(in vec3 p, in vec2 t)
{
    vec2 q = vec2(length(p.xz)-t.x, p.y);
    return length(q)-t.y;
}

void main(void)
{
    vec2 p2 = (2.0*gl_FragCoord.xy-resolution.xy)/resolution.y;
    vec3 col = vec3(0.05);
    const float steps = 30.0;
    float pe = 3.0;
    for(float i = 0.0; i < steps; i++)
    {
        float r = i/steps;
        float z = -1.0+2.0*r*r;
        z *= 3.0;
        float s = pe/(pe+z);
        vec3 p3 = vec3(p2*s, z);
        p3.zx = rotate(p3.zx, time*0.521);
        p3.yz = rotate(p3.yz, time*0.632);
        p3.x += 0.45;
        float de = sdTorus(p3,
            vec2(
                0.7*cos(time*1.678)+1.2,
                   0.35*(sin(time*1.234)+1.0)));
        de = smoothstep(0.08,0.0,de);
        if (de > 0.0 && de < 0.5)
        {
            col = vec3(r*0.5+0.5, 1.0-r, r*(sin(time*1.987)*2.0-1.0))*(1.0-de*2.0);
        }
    }
    glFragColor = vec4(col, 1.0);
}

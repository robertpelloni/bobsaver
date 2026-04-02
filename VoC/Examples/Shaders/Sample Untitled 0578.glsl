#version 420

// original https://www.shadertoy.com/view/wls3Wf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

mat2 rotation(float radian)
{
    float c = cos(radian);
    float s = sin(radian);
    return mat2(c, s, -s, c);
}

float sphere(vec3 pos, float radius)
{
    return length(pos) - radius;
}
float cylinder(vec3 pos, float radius)
{
    return length(pos.xy) - radius;
}
float box(vec3 pos, float radius)
{
    pos = abs(pos);
    return max(pos.x, max(pos.y, pos.z)) - radius;
}

float map(vec3 pos)
{
    //pos.z += time;
    pos.xy *= rotation(pos.z * 0.2);
    pos.z += time * .5;    
    //pos.yz *= rotation(time*0.05);
    
    float size = 2.5;
    pos = mod(pos, size) - size/2.;
    
    float s = sphere(pos, 0.75);
    float b = box(pos, 0.6);
    float geometry =  max(s, b);
    geometry = min(geometry, cylinder(pos, 0.3));
    geometry = min(geometry, cylinder(pos.xzy, 0.3));
    geometry = min(geometry, cylinder(pos.zyx, 0.3));
    return geometry;
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv = uv * 2. - 1.;
    uv.x *= resolution.x / resolution.y;
    
    float circle = length(uv) - 0.5;
    circle = step(0.4, circle);
    
    vec3 eye = vec3(0., 0., -2.);
    vec3 ray = normalize(vec3(uv, 1.));
    float shade = 0.;
    int nbLoop = 20;
    for (int i = 0; i < nbLoop; ++i)
    {
        float dist = map(eye);
        if (dist < 0.001)
        {
            shade = 1. - float(i)/float(nbLoop);
            break;
        }
        eye += ray * dist;
    }
    
    glFragColor = vec4(shade);
}

#version 420

// original https://www.shadertoy.com/view/tslXDB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// atan3 - messing around...

#define    PI 3.141592

vec3 pat(vec2 uv,float t)
{
    float ang = atan(uv.x, uv.y)/(2.*PI);
    float dist = length(uv);
    vec3 col = vec3(0.0);
    for (float ray = 0.5; ray < 8.0; ray += 0.26)
    {
        float rayang = t*ray/3.0/PI;
        rayang += sin(t*0.1+dist);
        rayang = fract(rayang-dist+(dist*(ray*0.5)));
        if (rayang < ang - 0.5)
            rayang += 1.0;
        if (rayang > ang + 0.5)
            rayang -= 1.0;
        float b = 0.3 - abs(ang - rayang)*2.0*PI;
        b -= dist * 0.3;
        if (b > 0.0)
            col.rgb += vec3(0.2+0.85*ray, 0.4+0.4*ray, 0.9+0.85*ray) *0.5*b;
    }
    col.rg *= 1.2+sin(dist+t*0.45)*0.25;
    return col;
}

void main(void)
{
    float t = time;
    vec2 uv = (2. * gl_FragCoord.xy - resolution.xy ) / resolution.y;
    uv /= dot(uv,uv);
    // wibble...
    uv.x += sin(uv.y*32.0+t*0.24)*0.01;
    uv.y += sin(uv.x*32.0+t*0.24)*0.01;
    uv *= 0.25;
    uv *= 1.5+sin(t*0.9);
    glFragColor = vec4( pat(uv,t)*0.6, 1.0);    
}

#version 420

// original https://www.shadertoy.com/view/wdlSDB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// atan1 - messing around...

#define    PI 3.141592

vec3 pat(vec2 uv,float t)
{
    float ang = atan(uv.x, uv.y)/(2.*PI);
    float dist = length(uv);
    //dist*=dist;
    vec3 col = vec3(0.3, 0.5, 0.7) * (pow(dist, -1.0) * 0.05);
    for (float ray = 0.5; ray < 8.0; ray += 0.6)
    {
        float rayang = t*ray/3.0/PI;
        rayang = fract(rayang-dist+(dist*(ray*0.5)));
        if (rayang < ang - 0.5)
            rayang += 1.0;
        if (rayang > ang + 0.5)
            rayang -= 1.0;
        float b = 0.3 - abs(ang - rayang)*2.0*PI;
        b -= dist * 0.3;
        if (b > 0.0)
            col.rgb += vec3(0.7+0.85*ray, 0.4+0.4*ray, 0.4+0.85*ray) *0.5*b;
    }
    col.g *= 1.2+sin(dist+t*0.45)*0.25;
    
    col.rb *= 0.75+sin(t*0.661+uv.x*uv.y)*0.5;
    
    return col;
}

void main(void)
{
    float t = time;
    vec2 uv = (2. * gl_FragCoord.xy - resolution.xy ) / resolution.y;
    uv *= 0.25;
    uv *= 1.1+sin(t*0.9);
    glFragColor = vec4( pat(uv,t), 1.0);    
}

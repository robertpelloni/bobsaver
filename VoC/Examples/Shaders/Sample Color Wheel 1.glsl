#version 420

// original https://www.shadertoy.com/view/MsXXzX

uniform float time;
uniform vec2 resolution;

out vec4 glFragColor;

#define ANIMATE

#define M_PI 3.1415926535897932384626433832795

//    0  1  2  3  4  5 
// R  1  1  0  0  0  1
// G  0  1  1  1  0  0
// B  0  0  0  1  1  1
vec3 getHueColor(vec2 pos)
{
#ifdef ANIMATE
    float theta = mod(3.0 + 3.0 * atan(pos.x, pos.y) / M_PI + time, 6.0);
#else
    float theta = 3.0 + 3.0 * atan(pos.x, pos.y) / M_PI;
#endif
        
    vec3 color = vec3(0.0);
    
    return clamp(abs(mod(theta + vec3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0, 0.0, 1.0);
}

void main(void)
{
    vec2 uv = vec2(2.0, -2.0) * (gl_FragCoord.xy - 0.5 * resolution.xy) / resolution.y;
    vec2 mouse = vec2(0.0,0.0);
    
    float l = length(uv);
    float m = length(mouse);
    
    glFragColor = vec4(0.0);

    if (l >= 0.75 && l <= 1.0)
    {
        l = 1.0 - abs((l - 0.875) * 8.0);
        l = clamp(l * resolution.y * 0.0625, 0.0, 1.0); // Antialiasing approximation
        
        glFragColor = vec4(l * getHueColor(uv), l);
    }
    else if (l < 0.75)
    {
        vec3 pickedHueColor;
        
        if (m < 0.75 || m > 1.0)
        {
#ifdef ANIMATE
            mouse = vec2(sin(time), cos(time));
#else
            mouse = vec2(0.0, -1.0);
            pickedHueColor = vec3(1.0, 0.0, 0.0);
#endif
        }
#ifndef ANIMATE
        else
        {
#endif
            pickedHueColor = getHueColor(mouse);
#ifndef ANIMATE
        }
#endif
        
        uv = uv / 0.75;
        mouse = normalize(mouse);
        
        float sat = 1.5 - (dot(uv, mouse) + 0.5); // [0.0,1.5]
        
        if (sat < 1.5)
        {
            float h = sat / sqrt(3.0);
            vec2 om = vec2(cross(vec3(mouse, 0.0), vec3(0.0, 0.0, 1.0)));
            float lum = dot(uv, om);
            
            if (abs(lum) <= h)
            {
                glFragColor = vec4(mix(pickedHueColor, vec3(0.5 * (lum + h) / h), sat / 1.5), 1.0);
            }
        }
    }
}

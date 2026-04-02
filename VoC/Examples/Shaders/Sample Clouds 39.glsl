#version 420

// original https://www.shadertoy.com/view/ll3yzB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//https://www.shadertoy.com/view/4djSRW
//#define HASHSCALE3 vec3(443.897, 441.423, 437.195)
#define HASHSCALE3 vec3(123.34, 234.34, 345.65)

vec2 hash22(vec2 p)
{
    vec3 p3 = fract(vec3(p.xyx) * HASHSCALE3);
    p3 += dot(p3, p3.yzx+19.19);
    return fract((p3.xx+p3.yz)*p3.zy);
}

float worley_noise_2(vec2 uv, float t) {
    vec2 f = fract(uv)-.5;    
    vec2 id = floor(uv);
    float min_dist = 8.0;
    
    for(float y = -1.0; y <= 1.0; ++y) 
    {
        for(float x = -1.0; x <= 1.0; ++x) 
        {
            vec2 offset = vec2(x, y);
            vec2 rand = hash22(id + offset);
            vec2 p = offset + sin(rand * t) * 0.5;
            vec2 r = f-p;
            
            float d = dot(r,r);

            if (d < min_dist)
                min_dist = d;
        }
    }
    
    return sqrt(min_dist);
}

float worley_fbm(vec2 uv, float t, float scale, float amplitude, float octaves) {
    
    float f = 0.0;
    
    for (float i = 0.0; i < octaves; i++)
    {
        f += worley_noise_2(uv * scale, t) * amplitude;
        amplitude *= .5;
        scale *= 2.;
    }
    
    return f;
}

void main(void) {
    
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv.x *= resolution.x/resolution.y;
    uv -= vec2(time*0.0055, time*0.003);
    
    vec3 sky_color = vec3(0.17, 0.31, 0.8);
    vec3 clouds_color = vec3(1.0);
    
    float speed = time * 0.0262 + 150.0;
    float scale = 2.2;
    float amplitude = sin(time*0.15)*0.4+1.2; //[.8 .. 1.6]
    float octaves = 16.0;
    float w = worley_fbm(uv, speed, scale, amplitude, octaves);
    float f = 1.0 - min(w, 1.0);
    
    glFragColor = vec4(mix(sky_color, clouds_color, f), 1.0);
}

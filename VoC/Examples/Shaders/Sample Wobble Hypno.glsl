#version 420

// original https://www.shadertoy.com/view/ctS3W1

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define pi 3.14159265359

// @FabriceNeyret2 antialias
float antialias(in float value)
{
    return smoothstep(-1., 1., (value-.5)/fwidth(value));
}

// Generate oscillation in the range [0, 1]
// with specified frequency "freq" (1/rad)
// at frame "theta"
float oscillator(in float theta, in float freq)
{
    return 0.5*sin(theta*freq*2.0/pi)+0.5;
}

float wobble(in float d)
{
    float c1 = sin(0.2*time+d*10.0);
    float c2 = sin(-0.1*time+d*24.0);
    float c3 = sin(-0.5*time+d*2.0*sin(c1));
    return 0.5*(3.0*c1 + 1.0*c2 + 5.0*c3 + d);
}

float wobble2(in float d)
{
    float w = 0.0;
    for (int i = 0; i < 4; i++)
    {
        w += 0.2*wobble(d) * (1.0 + sin(w*w));
    }
    return w;
}

#define dark vec3(0.1, 0.0, 0.15)
#define light vec3(0.94, 0.95, 1.0)
#define limit vec3(1.0, 0.4, 0.1)

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    // + Moved to center, no asymetric stretch
    vec2 uv = (gl_FragCoord.xy - resolution.xy/2.0)/resolution.x;

    // Theta/Radius at current pixel
    float tin = atan(uv.y, uv.x);
    float rin = length(uv);
    
    // Phase offset theta in function of radius at current pixel
    float theta = tin + (1.0 + wobble2(rin));
    
    // Generate B/W spiral
    float v = oscillator(theta, 7.0*pi);
    v = smoothstep(-1., 1., (v-.5)/fwidth(v));
    
    // 
    vec3 col = mix(dark, light, v);
    col = mix(col, limit, smoothstep(0., 1.5/resolution.x, rin-.24)); // @FabriceNeyret2 antialiased mix
    
    // Output
    glFragColor = vec4(col,1.0);
}

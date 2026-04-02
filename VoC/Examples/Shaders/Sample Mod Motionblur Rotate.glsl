#version 420

// original https://www.shadertoy.com/view/wdtXWn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 rotate(vec2 uv,float rot)
{
    // rotation matrix
    float s = sin(-rot);
    float c = cos(-rot);
    return mat2x2(c,s,-s,c)*uv;
}

vec3 calcColor(vec2 uv, float t)
{
    vec2 uv2 = rotate(uv, sin(t*0.2)*6.28);
    float d;
    // mod
    vec2 uv3 = mod(uv2, 0.3) / 0.3;
    // lattice
    if(uv3.x < 0.1 || uv3.y < 0.1)
    {
        return vec3(1.0,1.0,1.0);
    }
    return vec3(abs(uv3.x),abs(uv3.y),sin(t)*0.5+0.5);
}

vec4 motionBlur(vec2 uv, float Freq)
{
    float doubleFreq = Freq * Freq;
    vec3 col = vec3(.0,.0,.0);
    for(float i=0.0;i<Freq;i++)
    {
        // ∫x dx = (1/2)x^2 + C
        col += calcColor(uv, time - i / Freq * 0.1 )*((Freq - i) * 2.0 / doubleFreq);
    }
    
    return vec4(col,1.0);
    
}

void main(void)
{
    // Normalized pixel coordinates (from -1 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy * 2.0 - 1.0;
    
    // Output to screen
    glFragColor = motionBlur(uv,20.0);
}

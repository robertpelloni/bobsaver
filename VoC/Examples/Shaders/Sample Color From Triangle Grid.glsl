#version 420

// original https://www.shadertoy.com/view/3tSSWV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float Random1D(float seed)
{
    return fract(sin(seed)*32767.0);
}

float Random1DB(float seed)
{
    return fract(sin(seed)* (65536.0*3.14159265359));
}

float Random1DC(float seed)
{
    return fract(cos(seed)* (131072.0*2.718281828459));
}

float Random3D(vec3 p)
{
    vec3 comparator = vec3(
        12.34 * Random1D(p.x), 
        56.789 * Random1DB(p.y),
        12.987 * Random1DC(p.z));
    float alignment = dot(p, comparator);
    float amplitude = sin(alignment) * 32767.0;
    float random = fract(amplitude);
    return random;
}

vec4 ComputeTriangleGridPattern(vec2 pos, float scale)    
{
    mat2 m = mat2(1.0, -1.0 / 1.73, 0.0, 2.0 / 1.73);
    vec2 u = scale * pos * m;
    vec3 g = vec3(u, 1.0 - u.x - u.y);
    vec3 id = floor(g);
    g = fract(g);
    if (length(g) > 1.0) g = 1.0 - g;
    vec2 g2 = abs(2.0*fract(g.xy) - 1.0);
    float centerDistance = length(g2);

    float nodeDistance = length(1.0 - g2);

    float id1 = Random3D(id);
    return vec4(id1, max(g.x,g.y), nodeDistance,centerDistance);
}

vec4 ComputeWaveGradientRGB(float t, vec4 bias, vec4 scale, vec4 freq, vec4 phase)
{
    vec4 rgb = bias + scale * cos(6.28 * (freq * t + phase));
    return vec4(clamp(rgb.xyz,0.0,1.0), 1.0);
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv.y *= float(resolution.y) / float(resolution.x);
    
    uv += vec2(cos(time*0.2) + time*0.1,time * 0.05);

    vec4 cc = ComputeTriangleGridPattern(uv,5.0);
    
    vec4 bias = vec4(0.350,0.906,0.689,1.0);
    vec4 scale = vec4(0.772,0.114,0.263,1.0);
    vec4 freq = vec4(0.077,0.368,1.016,1.0);
    vec4 phase = vec4(3.859,3.252,5.857,1.0);
    
    vec4 color;
    if(cc.x < 0.25)
        color=ComputeWaveGradientRGB(1.0 + 0.5*cos(cc.y + cc.z + time), bias, scale, freq,phase);
    else if(cc.x < 0.5)
        color=ComputeWaveGradientRGB(tan(cc.w + time), bias, scale, freq, phase);
    else if(cc.x < 0.75)
        color = ComputeWaveGradientRGB(fract(cc.w/(cc.y+cc.z) + time), bias, scale, freq, phase);
    else
        color = ComputeWaveGradientRGB(tan(max(cc.w,cc.y) + time), bias, scale, freq, phase);
    
    
    // Output to screen
    glFragColor = vec4(color.xyz,1.0);
}

#version 420

// original https://www.shadertoy.com/view/3tjSW3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float SQRT3 = 1.73205; 
vec3 TRI30_60_90 = vec3(1.0, SQRT3, 2.0);

float Random1D(float seed)
{
    return fract(sin(seed)*32767.0);
}

float Random1DB(float seed)
{
    return fract(sin(seed)* (65536.0*3.14159265359));
}

float Random2D(vec2 p)
{
    vec2 comparator = vec2(
        12.34 * Random1D(p.x), 
        56.789 * Random1DB(p.y));
    float alignment = dot(p, comparator);
    float amplitude = sin(alignment) * 32767.0;
    float random = fract(amplitude);
    return random;
}

// from http://www.iquilezles.org/www/articles/distfunctions2d/distfunctions2d.htm
float HexagonDistance(vec2 p, float r)
{
    const vec3 k = vec3(-0.866025404, 0.5, 0.577350269);
    p = abs(p);
    p -= 2.0*min(dot(k.xy, p), 0.0)*k.xy;
    p -= vec2(clamp(p.x, -k.z*r, k.z*r), r);
    return length(p)*sign(p.y);
}

// http://glslsandbox.com/e#43182.0
// This function returns the hexagonal grid coordinate for the grid cell, and the corresponding 
// hexagon cell ID - in the form of the central hexagonal point. That's basically all you need to 
// produce a hexagonal grid.
vec4 HexagonGridId(vec2 p, float scale)
{
    p *= scale;
    
    vec4 center = floor(
        vec4(p, 
             p - vec2(0.5, 1.0)) / TRI30_60_90.xyxy) + 0.5;
    
    vec4 h = vec4(p - center.xy*TRI30_60_90.xy, p - (center.zw + 0.5)*TRI30_60_90.xy);
    return 
        dot(h.xy, h.xy) < dot(h.zw, h.zw) ? 
            vec4(h.xy, center.xy) 
          : vec4(h.zw, center.zw + 9.73);

}

vec4 ComputeHexagonGridPattern(vec2 p, float scale, float ccScale)
{
    vec4 h = HexagonGridId(p, scale);
    float hexScale = 1.0/scale;
    
    float edgeDistance =  HexagonDistance(h.xy,hexScale);
    float topo = fract(edgeDistance * ccScale);
    
    
    return vec4(edgeDistance, topo, h.z, h.w);
}

float Map( float range_a_point, float a0, float a1, float b0, float b1 )
{
    return (((range_a_point - a0) * (abs(b1-b0)))/abs(a1-a0)) + b0;
}

float Gain(float x, float k) 
{ 
    float a = 0.5*pow(2.0*((x<0.5)?x:1.0-x), k); 
    return (x<0.5)?a:1.0-a; 
}
    

vec4 ComputeHexBlobs(vec2 p, float grade, float scale)
{
    vec4 h = HexagonGridId(p, scale);    
    grade = clamp(grade,0.0,1.0);
    grade += 1.2;
   
      
    float cDistance = Gain(
        clamp((1.0/grade) - (length(h.xy)),0.0,1.0),
        grade * 0.8) 
        * grade;
    
    float blobDistance = cDistance;
    return vec4(blobDistance, h.zw, pow(cDistance,2.22)); 
    
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

    vec4 cc = ComputeHexBlobs(uv, 1.0 + 0.3*sin(time * 2.0), 10.0);
    
    
    vec4 bias = vec4(0.5f, 0.5f, 0.5f, 1.0f);
    vec4 scale = vec4(1.0f, 1.0f, 1.0f, 1.0f);
    vec4 freq = vec4(1.0f, 1.0f, 1.0f, 1.0f);
    vec4 phase = vec4(0.0f, 0.3333f, 0.6666f, 1.0f);
    

    vec4 color;
       color=ComputeWaveGradientRGB(Random2D(cc.yz), bias, scale, freq, phase);
    // color *= (cc.x + cc.w);
    color *= cc.x;
    
    
    // Output to screen
    glFragColor = vec4(color.xyz,1.0);
        
   
}

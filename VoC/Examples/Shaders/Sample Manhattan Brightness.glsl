#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/4ldfRr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const int k_gridW = 15;
const int k_gridH = 11;
const int k_phase = 8;
const float k_variationSpeed = 1.314f;

float rand2(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

vec3 ApplyBrightness(vec3 color, float brightness)
{
    vec3 result;
    vec3 Value = color * color;
    float luma =  dot(Value, vec3( 0.299, 0.587, 0.114))+0.001;    
    float expLuma = exp2(4.0*luma) - 1.0;
    Value *= expLuma/luma;
    result = Value * brightness;
    return result;
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    
    float xx = uv.x * float(k_gridW);
    float yy = uv.y * float(k_gridH);
    // Time varying pixel color
    int xi = int(xx);
    int yi = int(yy);
    
    int gridCenterW = k_gridW / 2;
    int gridCenterH = k_gridH / 2;
    
    int manhattanDistance = abs(xi - gridCenterW) + abs(yi - gridCenterH);
    int k = manhattanDistance % k_phase;
    float kf = float(k);

    float r = rand2(vec2(xi,xi));
    float g = rand2(vec2(xi,yi));
    float b = rand2(vec2(yi,xi));

    vec3 col = ApplyBrightness(vec3(r, g, b), 
                               smoothstep(1.0f, 0.0f, abs(sin((kf + time)))));

    // Output to screen
    glFragColor = vec4(col,1.0);
}

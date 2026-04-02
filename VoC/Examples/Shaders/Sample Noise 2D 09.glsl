#version 420

// N o i s e
// by Matteo Basei
// http://www.matteo-basei.it
// https://www.youtube.com/c/matteobasei

uniform vec2 resolution;
uniform vec2 mouse;
uniform float time;

out vec4 glFragColor;

const int OCTAVES = 10;
const float FREQUENCY = 10.0;
const float TURBULENCE_AMPLITUDE = 1.0;
const float TURBULENCE_FREQUENCY = 10.0;
const float SPEED = 0.1;
const bool COLOR = true;

vec3 hslToRgb(float hue, float saturation, float lightness)
{
    float hexaHue = 6.0 * hue;
    
    vec3 color;
    if      (hexaHue < 1.0) color = vec3( 0.5,                   -0.5 + hexaHue,        -0.5);
    else if (hexaHue < 2.0) color = vec3( 0.5 - (hexaHue - 1.0),  0.5,                  -0.5);
    else if (hexaHue < 3.0) color = vec3(-0.5,                    0.5,                  -0.5 + (hexaHue - 2.0));
    else if (hexaHue < 4.0) color = vec3(-0.5,                    0.5 - (hexaHue - 3.0), 0.5);
    else if (hexaHue < 5.0) color = vec3(-0.5 + (hexaHue - 4.0), -0.5,                   0.5);
    else                    color = vec3( 0.5,                   -0.5,                   0.5 - (hexaHue - 5.0));
    
    float chroma = saturation * (1.0 - abs(2.0 * lightness - 1.0));
    
    return color * chroma + lightness;
}

float pseudoRandom(vec2 point)
{
    return fract(100.0 * sin(point.x + 100.0 * point.y));
}

float pseudoRandom(vec3 point)
{
    return fract(100.0 * sin(point.x + 100.0 * point.y + 0.001 * point.z));
}

float valueNoise(vec2 point)
{
    vec2 floorPoint = floor(point);
    vec2 fractPoint = fract(point);
    vec2 smoothPoint = smoothstep(0.0, 1.0, fractPoint);

    float value00 = pseudoRandom(floorPoint + vec2(0, 0));
    float value01 = pseudoRandom(floorPoint + vec2(0, 1));
    float value10 = pseudoRandom(floorPoint + vec2(1, 0));
    float value11 = pseudoRandom(floorPoint + vec2(1, 1));

    float value0 = mix(value00, value01, smoothPoint.y);
    float value1 = mix(value10, value11, smoothPoint.y);

    float value = mix(value0, value1, smoothPoint.x);

    return 2.0 * value - 1.0;
}

float valueNoise(vec3 point)
{
    vec3 floorPoint = floor(point);
    vec3 fractPoint = fract(point);
    vec3 smoothPoint = smoothstep(0.0, 1.0, fractPoint);

    float value000 = pseudoRandom(floorPoint + vec3(0, 0, 0));
    float value001 = pseudoRandom(floorPoint + vec3(0, 0, 1));
    float value010 = pseudoRandom(floorPoint + vec3(0, 1, 0));
    float value011 = pseudoRandom(floorPoint + vec3(0, 1, 1));
    float value100 = pseudoRandom(floorPoint + vec3(1, 0, 0));
    float value101 = pseudoRandom(floorPoint + vec3(1, 0, 1));
    float value110 = pseudoRandom(floorPoint + vec3(1, 1, 0));
    float value111 = pseudoRandom(floorPoint + vec3(1, 1, 1));

    float value00 = mix(value000, value001, smoothPoint.z);
    float value01 = mix(value010, value011, smoothPoint.z);
    float value10 = mix(value100, value101, smoothPoint.z);
    float value11 = mix(value110, value111, smoothPoint.z);

    float value0 = mix(value00, value01, smoothPoint.y);
    float value1 = mix(value10, value11, smoothPoint.y);

    float value = mix(value0, value1, smoothPoint.x);
    
    return 2.0 * value - 1.0;
}

float fractalNoise(vec3 point, float frequency)
{
    float result = 0.0;
    float amplitude = 0.5;    
    
    for (int i = 0; i < OCTAVES; ++i)
    {
        result += valueNoise(point * frequency) * amplitude;
        
        frequency *= 2.0;
        amplitude /= 2.0;
    }
    
    return result;
}

void main()
{    
    vec2 pixel = 2.0 * gl_FragCoord.xy / resolution.xy - 1.0;
    pixel.y *= resolution.y / resolution.x;

    float frequency = FREQUENCY * mouse.x;
    float turbulenceAmplitude = TURBULENCE_AMPLITUDE * (1.0 - mouse.y);
    float turbulenceFrequency = TURBULENCE_FREQUENCY * (1.0 - mouse.y);

    vec3 point = vec3(pixel, SPEED * time);
    
    point += turbulenceAmplitude * fractalNoise(vec3(pixel, 1.0), turbulenceFrequency);

    float lightness = 0.5 + 0.5 * fractalNoise(point, frequency);
    
    if (COLOR)
    {
        float hue = mod(5.0 * (0.5 + 0.5 * fractalNoise(point, 0.1 * frequency)), 1.0);
        
        glFragColor = vec4(hslToRgb(hue, 0.5, lightness), 1.0);
    }
    else
    {
        glFragColor = vec4(vec3(lightness), 1.0);
    }
}

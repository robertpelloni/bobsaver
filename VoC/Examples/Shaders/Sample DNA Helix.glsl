#version 420

// original https://www.shadertoy.com/view/wsXBzr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define TIME (time)
#define SIN_DENSITY 0.4
#define COLOR_DIFFERENCE 0.8

float linearstep(float a, float b, float x)
{
     return clamp((b - x) / (b - a), 0.0, 1.0);
}

//x - circle alpha
//y - circle color
//Thanks to FabriceNeyret2 for this idea
vec2 circle(vec2 uv, float pixelSize, float sinDna, float cosDna, float _sign)
{
    float height = _sign * sinDna;
    float depth = abs((_sign * 0.5 + 0.5) - (cosDna * 0.25 + 0.5));    //this 0.25 is quite bad here
    float size = 0.2 + depth * 0.1;
    float alpha = 1.0 - smoothstep(size - pixelSize, 
                                   size + pixelSize, 
                                   distance(uv, vec2(0.5, height)));
    
    return vec2(
        alpha, 
        depth * COLOR_DIFFERENCE + (1.0 - COLOR_DIFFERENCE)
    );
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy * 2.0 - resolution.xy) / resolution.y;
    
    //scale
    uv *= 5.0;
    
    //rotation for angle=0.3
    //optimized version of uv *= mat2(cos(angle), sin(angle), -sin(angle), cos(angle)); by FabriceNeyret2
    float angle = 0.3;
    uv *= mat2(cos(angle + vec4(0,11,33,0)));

    //move over time
    uv.x -= TIME * 0.5;
    
    //basic variables
    float pixelSize = 10.0 / resolution.y;
    vec2 baseUV = uv;
    uv.x = fract(uv.x);
    float lineIndex = floor(baseUV.x);
    float dnaTimeIndex = lineIndex * SIN_DENSITY + TIME;
    float sinDna = sin(dnaTimeIndex) * 2.0;
    float cosDna = cos(dnaTimeIndex) * 2.0;
    
    //draw straight line
    float lineSDF = abs(uv.x - 0.5);
    float line = smoothstep(pixelSize * 2.0, 0.0, lineSDF);
    
    //cut upper part of the lines
    float sinCutLineUp = abs(sinDna);
    float sinCutMaskUp = smoothstep(sinCutLineUp + pixelSize, sinCutLineUp - pixelSize, uv.y);
    
    //cut lower part of the lines
    float sinCutLineDown = -abs(sinDna);
    float sinCutMaskDown = smoothstep(sinCutLineDown - pixelSize, sinCutLineDown + pixelSize, uv.y);
    
    //Create first side of dna circles
    vec2 circle1 = circle(uv, pixelSize, sinDna, cosDna, 1.0);
    
    //Second side of dna circles
    vec2 circle2 = circle(uv, pixelSize, sinDna, cosDna, -1.0);
    
    //Calculating line gradient for depth effect
    //Thanks to @tb for this 3D effect idea
    float lineGradient = linearstep(sinCutLineUp, sinCutLineDown, uv.y);
    if (sin(lineIndex * SIN_DENSITY + TIME) > 0.0) lineGradient = 1.0 - lineGradient;
    lineGradient = mix(circle1.y, circle2.y, lineGradient);
    
    //rendering line
    float helis = 0.0;
    
    //rendering circles 
    if (circle1.y < circle2.y)
    {
        helis = mix(helis, circle1.y, circle1.x);
        helis = mix(helis, lineGradient, line * sinCutMaskUp * sinCutMaskDown);
        helis = mix(helis, circle2.y, circle2.x);
    }
    else
    {
        helis = mix(helis, circle2.y, circle2.x);
        helis = mix(helis, lineGradient, line * sinCutMaskUp * sinCutMaskDown);
        helis = mix(helis, circle1.y, circle1.x);
    }
    
    glFragColor = vec4(helis);
}

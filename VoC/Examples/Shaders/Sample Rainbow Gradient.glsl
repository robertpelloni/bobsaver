#version 420

// original https://www.shadertoy.com/view/MsjSzc

uniform float time;
uniform vec2 resolution;

out vec4 glFragColor;

//Divided per 7 -> 1/7 = 0.1428571428571429
float Maskline(float pos,float lineNumber)
{    
  return step(pos,0.1428571428571429 * lineNumber) - (step(pos,0.1428571428571429 * (lineNumber - 1.)));
}

vec3 GetRainbowColor(float i)
{
    //Step Violet
    vec3 Violet =     vec3(0.57,0.0, 1.0)     *  Maskline(i,7.);
    vec3 Purple =     vec3(0.27,0.0, 0.51)    *  Maskline(i,6.);
    vec3 blue     =    vec3(0.0,     0.0, 1.0)     *  Maskline(i,5.);
     vec3 Green    =    vec3(0.0,     1.0, 0.0)     *  Maskline(i,4.);
     vec3 Yellow =    vec3(1.0,     1.0, 0.0)     *  Maskline(i,3.);
    vec3 Orange =    vec3(1.0,     0.5, 0.0)     *  Maskline(i,2.);
     vec3 Red    =    vec3(1.0,     0.0, 0.0)     *  Maskline(i,1.);
    return Violet + Purple + blue + Green + Yellow + Orange + Red;
}

vec3 SmoothRainbowColor(float i)
{
    i *= 0.1428571428571429 * 6.;
    float gradinStep = mod(i,0.1428571428571429) * 7.;    
    vec3 firstColor = GetRainbowColor(i);
    vec3 NextColor = GetRainbowColor(i + 0.1428571428571429);    
    return mix(firstColor,NextColor, gradinStep);
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    float vStep = step(uv.y,0.5);    
    vec3 c = SmoothRainbowColor(uv.x) * (1. - vStep);
    c += GetRainbowColor(uv.x  ) * vStep;    
    glFragColor = vec4(c,1.0);
}

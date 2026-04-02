#version 420

// original https://www.shadertoy.com/view/4lXcD7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//////////////////////////////////////////////////////////////////////////////////
// Color Stretch - Copyright 2019 Frank Force
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
//////////////////////////////////////////////////////////////////////////////////

const float zoomSpeed            = .5;    // how fast to zoom (negative to zoom out)
const float zoomScale            = 0.1;    // how much to multiply overall zoom (closer to zero zooms in)
const int recursionCount        = 6;    // how deep to recurse
const int glyphSize                = 3;    // width & height of glyph in pixels
const float curvature            = 0.0;    // time warp to add curvature

//////////////////////////////////////////////////////////////////////////////////
// Precached values and math

const float glyphSizeF = float(glyphSize);
const float glyphSizeLog = log(glyphSizeF);
const float e = 2.718281828459;
const float pi = 3.14159265359;

float RandFloat(int i) { return (fract(sin(float(i)) * 43758.5453)); }
int RandInt(int i) { return int(100000.0*RandFloat(i)); }

vec3 HsvToRgb(vec3 c) 
{
    float s = c.y * c.z;
    float s_n = c.z - s * .5;
    return vec3(s_n) + vec3(s) * cos(2.0 * pi * (c.x + vec3(1.0, 0.6666, .3333)));
}

//////////////////////////////////////////////////////////////////////////////////
// Color and image manipulation

float GetRecursionFade(int r, float timePercent)
{
    if (r > recursionCount)
        return timePercent;
    
    // fade in and out recusion
    float rt = max(float(r) - timePercent, 0.0);
    float rc = float(recursionCount);
    return rt / rc;
}

vec3 InitPixelColor() { return vec3(0, .5, .5); }
vec3 CombinePixelColor(vec3 color, float timePercent, int i, int r, vec2 pos, ivec2 glyphPos, ivec2 glyphPosLast)
{
    i = (i+r) + (glyphPosLast.y + glyphPos.y);
    //i+=glyphPosLast.x + glyphPos.x;

    vec3 myColor = vec3
    (
        mix(-0.3, 0.3, RandFloat(i)),
        mix(-0.2, 0.2, RandFloat(i + 10)),
        mix(-0.2, 0.2, RandFloat(i + 20))
    );

    // combine with my color
    float f = GetRecursionFade(r, timePercent);
    color += myColor*f;
    return color;
}

vec3 FinishPixel(vec3 color, vec2 uv)
{
    // color wander
    color.x += 0.03*time;
    
    // convert to rgb
    color = HsvToRgb(color);
    return color;
}

vec2 InitUV(vec2 uv)
{
   //v.y += 1.0;
    // wave
    //uv.x += 0.04*sin(10.0*uv.y + 0.17*time);
    //uv.y += 0.04*sin(10.0*uv.x + 0.13*time);
    //uv.x += 0.2*sin(2.0*uv.y + 0.31*time);
    //uv.y += 0.2*sin(2.0*uv.x + 0.27*time);
    
    // spin
    //float theta = 0.0;//pi/2.0;//0.05*time;
    //float c = cos(theta);
    //float s = sin(theta);
    //uv = vec2((uv.x*c - uv.y*s), (uv.x*s + uv.y*c));
    
    return uv;
}

//////////////////////////////////////////////////////////////////////////////////
// Fractal functions

ivec2 GetFocusPos(int i) { return ivec2(glyphSize/2); }
      
// get color of pos, where pos is 0-1 point in the glyph
vec3 GetPixelFractal(vec2 pos, int iterations, float timePercent)
{
    ivec2 glyphPosLast = GetFocusPos(-2);
    ivec2 glyphPos =     GetFocusPos(-1);
    vec3 color = InitPixelColor();
    
    for (int r = 0; r <= recursionCount + 1; ++r)
    {
        color = CombinePixelColor(color, timePercent, iterations, r, pos, glyphPos, glyphPosLast);
        if (r > recursionCount)
            return color;
           
        // update pos
        pos *= glyphSizeF;

        // get glyph and pos within that glyph
        glyphPosLast = glyphPos;
        glyphPos = ivec2(pos);
        
        // next glyph
        pos -= vec2(floor(pos));
    }
}
 
//////////////////////////////////////////////////////////////////////////////////
    
void main(void)
{
    // use square aspect ratio
    vec2 uv = gl_FragCoord.xy;
    uv = gl_FragCoord.xy / resolution.y;
    uv -= vec2(0.5*resolution.x / resolution.y, 0.5);
    uv = InitUV(uv);
    
    // time warp
    float time = time + curvature*pow(length(uv), 0.2);
    
    // time warp to add add some 3d curve
    //float c1 = 0.5*sin(0.3*time);
    //float c2 = 0.5*sin(0.23*time);
    //time += curvature*(c1*length(uv) + c2*uv.x*uv.y)*zoomSpeed;
    
    // get time 
    float timePercent = time*zoomSpeed;
    int iterations = int(floor(timePercent));
    timePercent -= float(iterations);
    
    // update zoom, apply pow to make rate constant
    float zoom = pow(e, -glyphSizeLog*timePercent);
    zoom *= zoomScale;
    
    // get offset
    vec2 offset = vec2(0);
    const float gsfi = 1.0 / glyphSizeF;
    for (int i = 0; i < 13; ++i)
        offset += (vec2(GetFocusPos(i)) * gsfi) * pow(gsfi,float(i));
    
    // apply zoom & offset
    vec2 uvFractal = uv * zoom + offset;
    
    // check pixel recursion depth
    vec3 pixelFractalColor = GetPixelFractal(uvFractal, iterations, timePercent);
    //pixelFractalColor.y = pow(pixelFractalColor.y, 2.);
    //pixelFractalColor.z = pow(pixelFractalColor.z, 2.);
    pixelFractalColor = FinishPixel(pixelFractalColor, uv);
    
    // apply final color
    glFragColor = vec4(pixelFractalColor, 1.0);
}

#version 420

// original https://www.shadertoy.com/view/4tlcWH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//////////////////////////////////////////////////////////////////////////////////
// Pixel Shrink Zoom - Copyright 2017 Frank Force
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
//////////////////////////////////////////////////////////////////////////////////

const float zoomSpeed            = -1.0;    // how fast to zoom (negative to zoom out)
const float zoomScale            = 0.3;    // how much to multiply overall zoom (closer to zero zooms in)
const int recursionCount        = 6;    // how deep to recurse
const float recursionFadeDepth    = 0.0;    // how deep to fade out
const int glyphSize                = 3;    // width & height of glyph in pixels
const int glyphCount            = 1;    // how many glyphs total
const float glyphMargin            = 0.0f;    // how much to center the glyph in each pixel

//////////////////////////////////////////////////////////////////////////////////
// Precached values and math

const float glyphSizeF = float(glyphSize) + 2.0*glyphMargin;
const float glyphSizeLog = log(glyphSizeF);
const int powTableCount = 10;
const float gsfi = 1.0 / glyphSizeF;
const float powTable[powTableCount] = float[]( 1.0, gsfi, pow(gsfi,2.0), pow(gsfi,3.0), pow(gsfi,4.0), pow(gsfi,5.0), pow(gsfi,6.0), pow(gsfi,7.0), pow(gsfi,8.0), pow(gsfi,9.0));
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
    float rt = max(float(r) - timePercent - recursionFadeDepth, 0.0);
    float rc = float(recursionCount) - recursionFadeDepth;
    return rt / rc;
}

vec3 InitPixelColor() { return vec3(0); }
vec3 CombinePixelColor(vec3 color, float timePercent, int i, int r, vec2 pos, ivec2 glyphPos, ivec2 glyphPosLast)
{
    i += r + 49*glyphPosLast.x + 73*glyphPosLast.y + 41*glyphPos.x + 53*glyphPos.y;
    
    vec3 myColor = vec3
    (
        mix(0.0, 0.4, RandFloat(i)),
        mix(0.0, 1.0, RandFloat(i + 1)),
        mix(0.0, 1.0, RandFloat(i + 2))
    );

    // combine with my color
    float f = GetRecursionFade(r, timePercent);
    myColor.y = pow(myColor.y, 3.0);
    myColor.z = pow(myColor.z, 3.0);
    color += myColor*f;
    return color;
}

vec3 FinishPixel(vec3 color, vec2 uv)
{
    // color wander
    color.x += 0.05*time;
    
    // convert to rgb
    color = HsvToRgb(color);
    return color;
}

vec2 InitUV(vec2 uv)
{
    //float theta = pi/4.0;
    //float c = cos(theta);
    //float s = sin(theta);
    //uv = vec2((uv.x*c - uv.y*s), (uv.x*s + uv.y*c));
    return uv;
}

//////////////////////////////////////////////////////////////////////////////////
// Fractal functions

int GetGlyphPixel(ivec2 pos, int g)
{
    if (pos.x >= glyphSize || pos.y >= glyphSize)
        return 0;

    return 1;
}

ivec2 GetFocusPos(int i) { return ivec2(glyphSize/2); }
      
// get color of pos, where pos is 0-1 point in the glyph
vec3 GetPixelFractal(vec2 pos, int iterations, float timePercent)
{
    int glyphLast = 0;
    ivec2 glyphPosLast = GetFocusPos(-2);
    ivec2 glyphPos =     GetFocusPos(-1);
    
    vec3 color = InitPixelColor();
    for (int r = 0; r <= recursionCount + 1; ++r)
    {
        color = CombinePixelColor(color, timePercent, iterations, r, pos, glyphPos, glyphPosLast);
        
        //if (r == 1 && glyphPos == GetFocusPos(r-1))
        //    color.z = 1.0; // debug - show focus
        
        if (r > recursionCount)
            return color;
           
        // update pos
        pos -= vec2(glyphMargin*gsfi);
        pos *= glyphSizeF;

        // get glyph and pos within that glyph
        glyphPosLast = glyphPos;
        glyphPos = ivec2(pos);

        // check pixel
        int glyphValue = GetGlyphPixel(glyphPos, glyphLast);
        if (glyphValue == 0 || pos.x < 0.0 || pos.y < 0.0)
            return color;
        
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
    
    // get time 
    float timePercent = time*zoomSpeed;
    int iterations = int(floor(timePercent));
    timePercent -= float(iterations);
    
    // update zoom, apply pow to make rate constant
    float zoom = pow(e, -glyphSizeLog*timePercent);
    zoom *= zoomScale;
    
    // get offset
    vec2 offset = vec2(0);
    for (int i = 0; i < powTableCount; ++i)
        offset += ((vec2(GetFocusPos(i)) + vec2(glyphMargin)) * gsfi) * powTable[i];
    
    // apply zoom & offset
    vec2 uvFractal = uv * zoom + offset;
    
    // check pixel recursion depth
    vec3 pixelFractalColor = GetPixelFractal(uvFractal, iterations, timePercent);
    pixelFractalColor = FinishPixel(pixelFractalColor, uv);
    
    // apply final color
    glFragColor = vec4(pixelFractalColor, 1.0);
}

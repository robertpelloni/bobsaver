#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/ldjfzh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//////////////////////////////////////////////////////////////////////////////////
// Dice Tumbler - Copyright 2017 Frank Force
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
//////////////////////////////////////////////////////////////////////////////////

const float zoomSpeed            = -1.3;    // how fast to zoom (negative to zoom out)
const float zoomScale            = 0.05;    // how much to multiply overall zoom (closer to zero zooms in)
const int recursionCount        = 5;    // how deep to recurse
const float recursionFadeDepth    = 0.0;    // how deep to fade out
const int glyphSize                = 3;    // width & height of glyph in pixels
const int glyphCount            = 12;    // how many glyphs total
const float glyphMargin            = 1.0f;    // how much to center the glyph in each pixel
const int glyph[glyphSize*glyphCount] = int[]
(// glyph sheet
 0x000, 0x100, 0x100, 0x101, 0x101, 0x101, 0x000, 0x001, 0x001, 0x101, 0x101, 0x111, 
 0x010, 0x000, 0x010, 0x000, 0x010, 0x101, 0x010, 0x000, 0x010, 0x000, 0x010, 0x000, 
 0x000, 0x001, 0x001, 0x101, 0x101, 0x101, 0x000, 0x100, 0x100, 0x101, 0x101, 0x111
);// 1    2      3       4     5      6      1      2      3      4      5      6
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
float Pow4(float f) { return f*f*f*f; }

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
    
    return 1.0;    // dont fade out
}

vec3 InitPixelColor() { return vec3(0.0, 1.0, 0.0); }
vec3 CombinePixelColor(vec3 color, float timePercent, int i, int r, vec2 pos, ivec2 glyphPos, ivec2 glyphPosLast)
{
    vec3 myColor = vec3
    (
        RandFloat(i + r + 419*glyphPosLast.x + 773*glyphPosLast.y),
        mix(0.05, 0.3, RandFloat(i + r + 929*glyphPosLast.x + 499*glyphPosLast.y)),
        1.0
    );

    // make alterate iteations black
    if ((i + r) % 2 == 0)
        myColor.z = 0.0;

    // make smaller and round corners
    float f = GetRecursionFade(r, timePercent);
    vec2 p = 2.0*(pos - vec2(0.5));
    p.x = sign(p.x)*Pow4(abs(p.x));
    p.y = sign(p.x)*Pow4(abs(p.y));
    if (length(p) > 0.2)
        f = 0.0;

    // combine with my color
    return mix(color, myColor, f);
}

vec3 FinishPixel(vec3 color, vec2 uv)
{
    // color wander
    color.x += (0.05*uv.y + 0.05*uv.x + 0.05*time);
    
    // convert to rgb
    color = HsvToRgb(color);
    return color;
}

vec2 InitUV(vec2 uv)
{
    // rotate over time
    float theta = 0.3*time;
    float c = cos(theta);
    float s = sin(theta);
    uv = vec2((uv.x*c - uv.y*s), (uv.x*s + uv.y*c));
    return uv;
}

//////////////////////////////////////////////////////////////////////////////////
// Fractal functions

int GetFocusGlyph(int i) { return RandInt(i) % glyphCount; }
int GetGlyphPixelRow(int y, int g) { return glyph[g + (glyphSize - 1 - y)*glyphCount]; }
int GetGlyphPixel(ivec2 pos, int g)
{
    if (pos.x >= glyphSize || pos.y >= glyphSize)
        return 0;

    // pull glyph out of hex
    int glyphRow = GetGlyphPixelRow(pos.y, g);
    return 1 & (glyphRow >> (glyphSize - 1 - pos.x) * 4);
}

ivec2 GetFocus(int i)
{
    // find a random valid pixel in glyph
    int g = GetFocusGlyph(i-1);
    int c = 0;
    for (int y = 0; y < glyphSize; ++y)
    {
        int glyphRow = GetGlyphPixelRow(y, g);
        for (int x = 0; x < glyphSize; ++x)
            c += (1 & (glyphRow >> 4*x));
    }

    c -= RandInt(i) % c;
    for (int y = 0; y < glyphSize; ++y)
    {
        int glyphRow = GetGlyphPixelRow(y, g);
        for (int x = 0; x < glyphSize; ++x)
        {
            c -= (1 & (glyphRow >> 4*x));
            if (c == 0)
                return ivec2(glyphSize - 1 - x,y);
        }
    }
}

// get recursion depth of pos, where pos is 0-1 point in the glyph
vec3 GetPixelFractal(vec2 pos, int iterations, float timePercent)
{
    ivec2 glyphPosLast = GetFocus(iterations-2);
    ivec2 glyphPos =     GetFocus(iterations-1);
    int g = GetFocusGlyph(iterations-1);
    
    vec3 color = InitPixelColor();
    for (int r = 0; r <= recursionCount + 1; ++r)
    {
        color = CombinePixelColor(color, timePercent, iterations, r, pos, glyphPos, glyphPosLast);
        
        int glyphValue = 0;
        if (r <= recursionCount)
        {
            // offset and bounds check
            pos -= vec2(glyphMargin/glyphSizeF);

            // get glyph and pos within that glyph
            glyphPosLast = glyphPos;
            glyphPos = ivec2(pos * glyphSizeF);

            // check depth
            glyphValue = GetGlyphPixel(glyphPos, g);
        }
        
        
        if (glyphValue == 0 || pos.x < 0.0 || pos.y < 0.0)
            return color;
        
        // update pos
        pos *= glyphSizeF;
        pos -= vec2(floor(pos));
        
        if (glyphPos == GetFocus(iterations+r))
            g = GetFocusGlyph(iterations+r); // inject correct glyph
        else
        {
            int i = iterations + r + glyphPos.x * 313 + glyphPos.y * 411 + glyphPosLast.x * 557 + glyphPosLast.y * 121;
            g = RandInt(i) % glyphCount;
        }
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
    int iterations = int(timePercent);
    timePercent -= floor(timePercent);
    
    // update zoom, apply pow to make rate constant
    float zoom = pow(e, -glyphSizeLog*timePercent);
    zoom *= zoomScale;
    
    // get offset
    vec2 offset = vec2(0);
    for (int i = 0; i < powTableCount; ++i)
        offset += ((vec2(GetFocus(iterations+i)) + vec2(glyphMargin)) / glyphSizeF) * powTable[i];
    
    // apply zoom & offset
    vec2 uvFractal = uv * zoom + offset;
    
    // check pixel recursion depth
    vec3 pixelFractalColor = GetPixelFractal(uvFractal, iterations, timePercent);
    pixelFractalColor = FinishPixel(pixelFractalColor, uv);
    
    // apply final color
    glFragColor = vec4(pixelFractalColor, 1.0);
}

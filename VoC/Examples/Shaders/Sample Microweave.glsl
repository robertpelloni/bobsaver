#version 420

// original https://www.shadertoy.com/view/wd23zD

#extension GL_EXT_gpu_shader4 : enable

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//////////////////////////////////////////////////////////////////////////////////
// Microweave - Copyright 2019 Frank Force
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
//////////////////////////////////////////////////////////////////////////////////

const float zoomSpeed            = 0.5;    // how fast to zoom (negative to zoom out)
const float zoomScale            = 0.1;    // how much to multiply overall zoom (closer to zero zooms in)
const int recursionCount        = 5;    // how deep to recurse
const float recursionFadeDepth    = 0.0;    // how deep to fade out
const int glyphSize                = 5;    // width & height of glyph in pixels
const int glyphCount            = 17;    // how many glyphs total
const float glyphMargin            = 0.0;    // how much to center the glyph in each pixel
const float timeWarp            = -2.0;    // time warp to add curvature
const int glyphs[glyphSize*glyphCount] = int[]
(// glyph sheet - pipes corospond to neighbor connection bits
 0x00000, 0x00000, 0x00000, 0x00000, 0x00000, 0x00000, 0x00000, 0x00000, 0x0DFE0, 0x0DFE0, 0x0DFE0, 0x0DFE0, 0x0DFE0, 0x0DFE0, 0x0DFE0, 0x0DFE0, 0x09BA0,
 0x05760, 0x00057, 0x76000, 0x77777, 0x00000, 0x00577, 0x77600, 0x77777, 0x09FA0, 0x0DFF7, 0x7FFE0, 0x7FFF7, 0x0DFE0, 0x0DFF7, 0x7FFE0, 0x6DFE5, 0x77777,
 0x0DFE0, 0x001FF, 0xFF200, 0xFFFFF, 0x00400, 0x05FFF, 0xFFF60, 0xFFFFF, 0x00800, 0x09FFF, 0xFFFA0, 0xFFFFF, 0x0DFE0, 0x0DFFF, 0xFFFE0, 0xEDFED, 0xFFFFF,
 0x09BA0, 0x0009B, 0xBA000, 0xBBBBB, 0x05F60, 0x0DFFB, 0xBFFE0, 0xBFFFB, 0x00000, 0x009BB, 0xBBA00, 0xBBBBB, 0x0DFE0, 0x0DFFB, 0xBFFE0, 0xADFE9, 0xBBBBB,
 0x00000, 0x00000, 0x00000, 0x00000, 0x0DFE0, 0x0DFE0, 0x0DFE0, 0x0DFE0, 0x00000, 0x00000, 0x00000, 0x00000, 0x0DFE0, 0x0DFE0, 0x0DFE0, 0x0DFE0, 0x05760
);// o       x-       -x       ╾        ,       ┍        ┑       ┭       '       ┖        ┚       ┶       ┃      ┝         ┦       ╀      ╀   
//0000=0   0001=1   0010=2   0011=3   0100=4   0101=5   0110=6   0111=7   1000=8   1001=9   1010=A   1011=B   1100=C   1101=D   1110=E   1111=F 
//TBLR     TBLR     TBLR     TBLR     TBLR     TBLR     TBLR     TBLR     TBLR     TBLR     TBLR     TBLR     TBLR     TBLR     TBLR     TBLR

//////////////////////////////////////////////////////////////////////////////////
// Precached values and math

const float glyphSizeF = float(glyphSize) + 2.0*glyphMargin;
const float glyphSizeLog = log(glyphSizeF);
const int powTableCount = 8;
const float gsfi = 1.0 / glyphSizeF;
const float powTable[powTableCount] = float[]( 1.0, gsfi, pow(gsfi,2.0), pow(gsfi,3.0), pow(gsfi,4.0), pow(gsfi,5.0), pow(gsfi,6.0), pow(gsfi,7.0));
const float e = 2.718281828459;
const float pi = 3.14159265359;

float RandFloat(int i) { return (fract(sin(float(i)) * 43758.5433)); }
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

float GetRecursionFade2(int r, float timePercent)
{
    if (r > recursionCount)
       return 0.0;
    if (r > recursionCount - 1)
        return timePercent;
    return 1.0;
}

vec2 Pow4(vec2 f) { return f*f*f*f; }
vec3 InitPixelColor() { return vec3(0.0, 0.3, 0.0); }
vec3 CombinePixelColor(vec3 color, float timePercent, int i, int r, vec2 pos, ivec2 glyphPos, ivec2 glyphPosLast)
{
    vec3 myColor = vec3(0.0,1.0,0.0);
    
    myColor.x = mix( 0.3, 0.3, RandFloat(i + r + 419*glyphPosLast.x + 773*glyphPosLast.y));
    myColor.x = mix( 0.0, 0.5, RandFloat(i + r));
    
    // make alterate iteations black
    if ((i + r) % 2 == 0)
        myColor.z = 1.0;
    
    float f2 = GetRecursionFade2(r, timePercent);
    myColor.z = mix( 0.5f, myColor.z, f2);

    // combine with my color
    color.z = myColor.z;
    float f = GetRecursionFade(r, timePercent);
    color.x += f*myColor.x;
    
    return color;
}

vec3 FinishPixel(vec3 color, vec2 uv)
{
    // rotate over time
    float theta = 0.01177*time;
    float c = cos(theta);
    float s = sin(theta);
    uv *= mat2(-s, c, c, s);
    
    // color wander
    color.x += (0.1*uv.y + 0.1*uv.x + 0.1*time);
    
    // convert to rgb
    color = HsvToRgb(color);
    return color;
}

vec2 InitUV(vec2 uv)
{
    // wave
    uv.x += 0.005*sin(10.0*uv.y + 0.51*time);
    uv.y += 0.005*sin(10.0*uv.x + 0.53*time);
    uv.x += 0.05*sin(2.0*uv.y + 0.57*time);
    uv.y += 0.05*sin(2.0*uv.x + 0.55*time);
    
    // rotate over time
    float theta = 0.01*time;
    float c = cos(theta);
    float s = sin(theta);
    uv = vec2((uv.x*c - uv.y*s), (uv.x*s + uv.y*c));
    
    return uv;
}

float TimeWarp(vec2 uv)
{
    // time warp to add add some 3d curve
    return timeWarp*(uv.x*uv.x + uv.y*uv.y);
}

//////////////////////////////////////////////////////////////////////////////////
// Fractal functions

int GetFocusGlyph(int i) 
{ 
    //return 15 + RandInt(i) % 2; 
    return RandInt(i) % 15; 
}
int GetGlyphPixelRow(int y, int g) { return glyphs[g + (glyphSize - 1 - y)*glyphCount]; }

int GetGlyphPixel(ivec2 pos, int g)
{
    // pull glyph out of hex
    int glyphRow = GetGlyphPixelRow(pos.y, g);
    return min(1, 0xF & (glyphRow >> (glyphSize - 1 - pos.x) * 4));
}

ivec2 focusList[max(powTableCount, recursionCount) + 2];
ivec2 GetFocusPos(int i) { return focusList[i+2]; }

int neighborsGrid[glyphSize*glyphSize];
void GetNeighbors(int lastGlyph)
{
    for (int y = glyphCount*(glyphSize - 1), z = -1; y >= 0; y -= glyphCount)
    {
        int glyphRow = glyphs[lastGlyph + y];
        for (int x = 4*(glyphSize-1); x >= 0; x -= 4)
            neighborsGrid[++z] = (0xF & (glyphRow >> x));
    }
    
    // slower way of building neigbors if not precomputed
    /*for (int y = 0; y < glyphSize; ++y)
    for (int x = 0; x < glyphSize; ++x)
    {
        int neighbors = 0;
        if (GetGlyphPixel(ivec2(x, y), lastGlyph) != 0)
        {
            neighbors |= GetGlyphPixel(ivec2(x+1, y), lastGlyph) << 0; // right
            neighbors |= GetGlyphPixel(ivec2(x-1, y), lastGlyph) << 1; // left
            neighbors |= GetGlyphPixel(ivec2(x, y-1), lastGlyph) << 2; // top
            neighbors |= GetGlyphPixel(ivec2(x, y+1), lastGlyph) << 3; // bottom
        }
        
        neighborsGrid[x + y*glyphSize] = neighbors;
    }*/
}

ivec2 CalculateFocusPos(int iterations)
{
    int glyphLast = GetFocusGlyph(iterations-1);
    
      // current focus glyph must appear in correct location
    int focusGlyph = GetFocusGlyph(iterations); 
    
    // find all pixels that have the right neighbors (or more) for focus glyph
    ivec2 validPlaces[glyphSize*glyphSize];
    int c = 0;
    
    ivec2 pos;
    for (int y = glyphCount*(glyphSize - 2), z = -1; y >= 1; y -= glyphCount)
    {
        int glyphRow = glyphs[glyphLast + y];
        for (int x = 4*(glyphSize-2); x >= 1; x -= 4)
        {
            int neighbors = (0xF & (glyphRow >> x));
            if (neighbors > 0 && ((neighbors & focusGlyph) == focusGlyph))
                validPlaces[c++] = ivec2(glyphSize - 1 - x/4, glyphSize - 1 -y/glyphCount);
        }
    }

    // pick one at random
    return validPlaces[RandInt(iterations) % c];
}
  
int GetGlyph(int iterations, ivec2 glyphPos, int glyphLast, ivec2 glyphPosLast, bool isFocus, ivec2 focusPos)
{ 
    GetNeighbors(glyphLast);

    // randomly remove some links
    int r = iterations + 17*glyphPosLast.x + 23*glyphPosLast.y;
    // random change over time
    //r += 23*int(0.01*float((11*glyphPos.x + 7*glyphPos.y + 17*glyphPosLast.x + 13*glyphPosLast.y))+ float(glyphLast)/float(glyphCount) + 0.1*time);
    
       int removeCount = RandInt(++r) % 3;
    for (int i = 0; i < removeCount; ++i)
    {
        int x = RandInt(++r) % (glyphSize);
        int y = RandInt(++r) % (glyphSize);
        
        // remove a link
        int neighbors = neighborsGrid[x + y*glyphSize];
        int bit = 3*(RandInt(++r) % 2);
        neighbors = neighbors & ~(1 << bit);
        
        // prevent orphans
        if (neighbors == 0 && (RandInt(++r) % 5 < 4))
            continue;
        if (bit == 0)
        {
            if (x == glyphSize-1) continue;
            int n = neighborsGrid[(x+1) + y*glyphSize] & ~(1 << 1);
            if (n == 0) continue;
            neighborsGrid[(x+1) + y*glyphSize] = n;
        }
        if (bit == 3)
        {
            if (y == glyphSize-1) continue;
            int n = neighborsGrid[x + (y+1)*glyphSize] & ~(1 << 2);
            if (n == 0) continue;
            neighborsGrid[x + (y+1)*glyphSize] = n;
        }
        
        neighborsGrid[x + y*glyphSize] = neighbors;
    }
    
    if (isFocus)
    {
        // stamp down the focus glyph
        int x = focusPos.x;
        int y = focusPos.y*glyphSize;
        int n = GetFocusGlyph(iterations);
        neighborsGrid[x + y] = n; 
        
        // fix up neighbors
        neighborsGrid[(x-1) + y] = (0 == (n & (1 << 1)))? 
            neighborsGrid[(x-1) + y] & ~(1 << 0) : neighborsGrid[(x-1) + y] | (1 << 0);
        neighborsGrid[(x+1) + y] = (0 == (n & (1 << 0)))?
            neighborsGrid[(x+1) + y] & ~(1 << 1) : neighborsGrid[(x+1) + y] | (1 << 1);
        neighborsGrid[x + y-glyphSize] = (0 == (n & (1 << 2)))?
            neighborsGrid[x + y-glyphSize] & ~(1 << 3) : neighborsGrid[x + y-glyphSize] | (1 << 3);
        neighborsGrid[x + y+glyphSize] = (0 == (n & (1 << 3)))?
            neighborsGrid[x + y+glyphSize] & ~(1 << 2) : neighborsGrid[x + y+glyphSize] | (1 << 2);
    }
    
    int glpyh = neighborsGrid[glyphPos.x + glyphPos.y*glyphSize];
    
    // do the weave
    if (glpyh == 15 && ((glyphPos.x + glyphPos.y + glyphPosLast.x + glyphPosLast.y) % 2 == 0))
        glpyh = 16;
    
    return glpyh;
}

// get color of pos, where pos is 0-1 point in the glyph
vec3 GetPixelFractal(vec2 pos, int iterations, float timePercent)
{
    int glyphLast = GetFocusGlyph(iterations-1);
    ivec2 glyphPosLast = GetFocusPos(-2);
    ivec2 glyphPos =     GetFocusPos(-1);
    
    bool isFocus = true;
    ivec2 focusPos = glyphPos;
    
    vec3 color = InitPixelColor();
    for (int r = 0; r <= recursionCount + 1; ++r)
    {
        color = CombinePixelColor(color, timePercent, iterations, r, pos, glyphPos, glyphPosLast);
        
        //if (isFocus && r == 3 && glyphPos == GetFocusPos(r-1))
        //    color.z += 1.0; // debug - show focus
        
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
        if (glyphValue == 0)
            return color;
        
        // next glyph
        pos -= vec2(floor(pos));
        focusPos = isFocus? GetFocusPos(r) : ivec2(-10);
        glyphLast = GetGlyph(iterations + r, glyphPos, glyphLast, glyphPosLast, isFocus, focusPos);
        isFocus = (glyphPos == focusPos);
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
    float timePercent = (3.0 + time + 180.+TimeWarp(uv))*zoomSpeed;
    int iterations = int(floor(timePercent));
    timePercent -= float(iterations);;
    
    // update zoom, apply pow to make rate constant
    float zoom = pow(e, -glyphSizeLog*timePercent);
    zoom *= zoomScale;
    
    // cache focus positions
    for(int i = 0; i  < powTableCount + 2; ++i)
      focusList[i] = CalculateFocusPos(iterations+i-2);
    
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

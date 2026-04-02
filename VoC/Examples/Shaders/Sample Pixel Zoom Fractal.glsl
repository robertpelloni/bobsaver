#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/XdXfzS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Pixel Zoom Fractal
// Copyright 2017 Frank Force

//----------------------------------------------------------------------------------------------
// number printing (for debug prints only)
// adapted from https://www.shadertoy.com/view/Ms3XWN

float SampleDigit(const in float n, const in vec2 vUV)
{
    if( abs(vUV.x-0.5)>0.5 || abs(vUV.y-0.5)>0.5 ) return 0.0;

    // digit data by P_Malin (https://www.shadertoy.com/view/4sf3RN)
    float data = 0.0;
         if(n < 0.5) data = 7.0 + 5.0*16.0 + 5.0*256.0 + 5.0*4096.0 + 7.0*65536.0;
    else if(n < 1.5) data = 2.0 + 2.0*16.0 + 2.0*256.0 + 2.0*4096.0 + 2.0*65536.0;
    else if(n < 2.5) data = 7.0 + 1.0*16.0 + 7.0*256.0 + 4.0*4096.0 + 7.0*65536.0;
    else if(n < 3.5) data = 7.0 + 4.0*16.0 + 7.0*256.0 + 4.0*4096.0 + 7.0*65536.0;
    else if(n < 4.5) data = 4.0 + 7.0*16.0 + 5.0*256.0 + 1.0*4096.0 + 1.0*65536.0;
    else if(n < 5.5) data = 7.0 + 4.0*16.0 + 7.0*256.0 + 1.0*4096.0 + 7.0*65536.0;
    else if(n < 6.5) data = 7.0 + 5.0*16.0 + 7.0*256.0 + 1.0*4096.0 + 7.0*65536.0;
    else if(n < 7.5) data = 4.0 + 4.0*16.0 + 4.0*256.0 + 4.0*4096.0 + 7.0*65536.0;
    else if(n < 8.5) data = 7.0 + 5.0*16.0 + 7.0*256.0 + 5.0*4096.0 + 7.0*65536.0;
    else if(n < 9.5) data = 7.0 + 4.0*16.0 + 7.0*256.0 + 5.0*4096.0 + 7.0*65536.0;
    
    vec2 vPixel = floor(vUV * vec2(4.0, 5.0));
    float fIndex = vPixel.x + (vPixel.y * 4.0);
    
    return mod(floor(data / pow(2.0, fIndex)), 2.0);
}

float PrintInt( in vec2 uv, in int value )
{
    float res = 0.0;
    float maxDigits = 1.0+ceil(.01+log2(float(value) + 1.0)/log2(10.0));
    float digitID = floor(uv.x);
    if( digitID > 0.0 && digitID < maxDigits )
    {
        float digitVa = mod( floor( float(value)/pow(10.0,maxDigits-1.0-digitID) ), 10.0 );
        res = SampleDigit( digitVa, vec2(fract(uv.x), uv.y) );
    }

    return res;
}

///////////////////////////////////////////////////////////////////////////////////
// pixel zoom config

const float zoomSpeed = 0.3;
const float zoomStart = 0.2;
    
const int recursionCount = 5;
const int glyphSize = 5;
const float glyphSizeF = float(glyphSize + 1);
const float glyphSizeLog = log(glyphSizeF);

const int glyphCount = 2;
const int glyph[glyphSize*glyphSize*glyphCount] =
int[](
    1,1,1,1,1,  0,1,1,1,0, 
    1,1,1,1,1,  1,1,1,1,0,
    1,1,0,1,1,  0,1,1,1,0, 
    1,1,1,1,1,  0,1,1,1,0,
    1,1,1,1,1,  1,1,1,1,1
);

/*const int glyphCount = 1;
const int glyph[glyphSize*glyphSize*glyphCount] =
//int[](
//  1, 1, 1, 1, 1, 
//  1, 0, 0, 0, 0, 
//  1, 1, 1, 1, 0, 
//  1, 0, 0, 0, 0, 
//  1, 0, 0, 0, 0 );
*/

int CheckGlyph(int x, int y, int g)
{
    if (x >= glyphSize || y == 0)
        return 0;
    
    return glyph[ x + g*glyphSize + (glyphSize - y) * glyphCount*glyphSize];
}

const int focusCount = 7;
const vec2 focusList[focusCount] =
vec2[]( 
    vec2(3, 1), // 0 - 0
    vec2(0, 1), // 1 - 1
    vec2(2, 3), // 2 - 0
    vec2(3, 0), // 3 - 1
    vec2(1, 2), // 4 - 1
    vec2(1, 4), // 5 - 0
    vec2(0, 2)  // 6 - 0
);
const int focusGlyphList[focusCount] =
int[]( 0, 0, 1, 0, 1, 1, 0);

vec2 GetFocus(int i) { return (focusList[i % focusCount] + vec2(0.5)) / glyphSizeF; }
int GetFocusGlyph(int i) { return focusGlyphList[i % focusCount]; }

int GetRand(int i, int x, int y, int x2, int y2)
{
    i += 3*x + 5*y;// + 3*x2*glyphSize + 5*y2*glyphSize;
    return GetFocusGlyph(i);
}

//////////////////////////////////////////////////////////////////////////////////

int IsPixel(vec2 pos, int r)
{
    vec2 focusLast = focusList[(r-1) % focusCount];
    int gpxLast = int(focusLast.x);
    int gpyLast = int(focusLast.y);
    
    vec2 focus = focusList[(r) % focusCount];
    int gpx = 0;//int(focus.x);
    int gpy = 0;//int(focus.y);
    
    // pos is point inside glyph from 0-1
    for (int i = 0; i <= recursionCount; ++i)
    {
        //g = GetRand(r + i, gpx, gpy, gpxLast, gpyLast);
        int g = GetRand(r + i, gpx, gpy, gpxLast, gpyLast);
        
            pos += vec2(-0.5,0.5)/glyphSizeF;
        vec2 glyphPos = pos * glyphSizeF;
        
        gpxLast = gpx;
        gpyLast = gpy;
          gpx = int(glyphPos.x);
          gpy = int(glyphPos.y);
        
        int glyphValye = CheckGlyph(gpx, gpy, g);
        
        if (pos.x < 0.0 || pos.y > 1.0)
            return i;
        else if (glyphValye != 1)
            return i;
        else if (i == recursionCount)
            return (glyphValye == 0)? i : i + 1;
        
        pos *= glyphSizeF;
        pos -= vec2(floor(pos.x), floor(pos.y));
    }
}
    
void main(void)
{
    const float e = 2.71828;
    
    // use square aspect ratio
    //vec2 uv = gl_FragCoord.xy / resolution.xy;
    vec2 uv = gl_FragCoord.xy;
    uv = gl_FragCoord.xy / resolution.y;
    uv -= vec2(0.5*resolution.x/resolution.y, 0.5);
    
    // wave
    uv.x += 0.1*sin(2.0*uv.y + 1.0*time);
    uv.y += 0.1*sin(2.0*uv.x + 0.8*time);
    
    // color wander
    vec4 tint;
    tint.r = .7 + .3*sin(0.8*uv.y +0.9*uv.x + 1.11*time);
    tint.g = .7 + .3*sin(7.0 + 1.5*uv.y +0.4*uv.x + 1.31*time);
    tint.b = .7 + .3*sin(11.0 +0.6*uv.y +1.8*uv.x + 1.61*time);
    tint.a = 1.;
    
    // get time
    float time = time*zoomSpeed;
    int depth = int(time);
       time = time - float(depth);
    float zoom = pow(e, (-glyphSizeLog)*time);
    zoom *= zoomStart;
    
    // get time
    vec2 offset = vec2(0);
    offset += GetFocus(depth);
       for (int i = 1; i < 5; i += 1)
        offset += GetFocus(depth+i) * pow(1.0 / glyphSizeF, float(i));
    
    // apply zoom
    uv *= zoom;
    uv += offset;
    //uv.x = clamp(uv.x, 0.0, 1.0);
    //uv.y = clamp(uv.y, 0.0, 1.0);
    
    // check pixel
    int i = IsPixel(uv, depth);
    
    // transition fade as it zooms
    float ft = float(i) - time;
    ft = max(ft, 0.0);
    float f = pow(ft / float(recursionCount + 1), 0.7);
    glFragColor = vec4(f);
    glFragColor *= tint;
    
    // debug info
    /*{
        // text printout
        vec2 fc = gl_FragCoord.xy / resolution.xy;
        glFragColor += vec4(PrintInt( (fc - vec2(0.0,0.5))*30.0, depth ));

        // show center
        if (fc.x > 0.49 && fc.x < 0.51 && fc.y > 0.49 && fc.y < 0.51) { glFragColor += 0.3; }
    }*/
}

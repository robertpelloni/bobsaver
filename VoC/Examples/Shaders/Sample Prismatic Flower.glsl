#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/MlXyRB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//////////////////////////////////////////////////////////////////////////////////
// Fractal Tunnel - Copyright 2017 Frank Force
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
//////////////////////////////////////////////////////////////////////////////////

const float zoomSpeed            = 0.5;    // how fast to zoom (negative to zoom out)
const float zoomScale            = 1.0;    // how much to multiply overall zoom (closer to zero zooms in)
const int recursionCount        = 4;    // how deep to recurse
const int glyphSize                = 3;    // width & height of glyph in pixels
const float curvature            = 12.5;    // time warp to add curvature

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

vec3 InitPixelColor() { return vec3(0); }
vec3 CombinePixelColor(vec3 color, float timePercent, int i, int r, vec2 pos, ivec2 glyphPos, ivec2 glyphPosLast)
{
    i = (i+r);
    //if (i % 2 == 0)
    //    i += (glyphPos.y + glyphPosLast.y);
    //    i += (glyphPos.x + glyphPosLast.x);
    if (glyphPos.y == 1 && glyphPos.x == 1)
        i += 211;    
    else if ((glyphPos.y + glyphPos.x) % 2 == 1)
        i += 111;

    vec3 myColor = vec3
    (
        mix(-0.7, 0.7, RandFloat(i)),
        mix(0.1, 0.6, RandFloat(i + 10)),
        mix(0.1, 0.7, RandFloat(i + 20))
    );
    
    //if (RandFloat(i+50) < 0.2)
    //    return vec3(0);
    

    // combine with my color
    float f = GetRecursionFade(r, timePercent);
    myColor.x = pow(myColor.x, 2.0);
    myColor.y = pow(myColor.y, 2.0);
    myColor.z = pow(myColor.z, 2.0);
    color += myColor*f;
    return color;
}

vec3 FinishPixel(vec3 color, vec2 uv)
{
    // color wander
    color.x += 0.01*time;
    
    //color.z = pow(color.z, 0.1);
    //color.z = pow(color.z, 0.1);
    
    // convert to rgb
    color = HsvToRgb(color);
    return color;
}

vec2 InitUV(vec2 uv)
{
    float theta = 0.05*time;
    float c = cos(theta);
    float s = sin(theta);
    uv = vec2((uv.x*c - uv.y*s), (uv.x*s + uv.y*c));
    
    //// wave
    uv.x += 0.02*sin(10.0*uv.y + 0.17*time);
    uv.y += 0.02*sin(10.0*uv.x + 0.13*time);
    uv.x += 0.05*sin(2.0*uv.y + 0.31*time);
    uv.y += 0.05*sin(2.0*uv.x + 0.27*time);
    
    
    float l = 4.0-length(uv);
    uv.x += 0.05*sin(0.2*time)*l;
    uv.y += 0.05*sin(0.23*time)*l;
    
    //uv.y *= -1.0;
    //uv.y += 1.0;
    
    //uv.y = pow(uv.y, 2.0);
    
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
    
    vec4 tweak = vec4(0.0, 90.0, 512.0, 300.0);    // preset
    //tweak = mouse*resolution.xy; // mouse control
    tweak -= vec4(320, 180, 320, 180);
    tweak /= vec4(320, 180, 320, 180);
    
    // time warp
    float time = time*zoomSpeed + curvature*(tweak.x)*(pow(length(1.0*uv), -1.0/(10.0*tweak.z)));
    
    // get time 
    float timePercent = time;
    int iterations = int(floor(timePercent));
    timePercent -= float(iterations);
    
    // update zoom, apply pow to make rate constant
    float zoom = pow(e, -glyphSizeLog*timePercent);
    zoom *= (tweak.y)*zoomScale*pow(length(uv), tweak.w);
    
    // get offset
    vec2 offset = vec2(0);
    const float gsfi = 1.0 / glyphSizeF;
    for (int i = 0; i < 13; ++i)
        offset += (vec2(GetFocusPos(i)) * gsfi) * pow(gsfi,float(i));
    
    // apply zoom & offset
    vec2 uvFractal = uv * zoom + offset;
    
    // check pixel recursion depth
    vec3 pixelFractalColor = GetPixelFractal(uvFractal, iterations, timePercent);
    pixelFractalColor = FinishPixel(pixelFractalColor, uv);
    
    // apply final color
    glFragColor = vec4(pixelFractalColor, 1.0);
}

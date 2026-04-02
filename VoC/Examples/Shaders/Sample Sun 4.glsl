#version 420

// original https://www.shadertoy.com/view/Ws3cRH

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define t float(frames)*0.0025

#define PI 3.14159365
#define TAU 6.28318531

const int colorsPerGradient = 5;

//---------------------------------------------------------------------------------
//--------------------------------Color Functions----------------------------------
//------------------by nmz: https://www.shadertoy.com/view/XddGRN------------------

//-----------------HSV-----------------

//HSV functions from iq (https://www.shadertoy.com/view/MsS3Wc)
#ifdef SMOOTH_HSV
vec3 hsv2rgb( in vec3 c )
{
    vec3 rgb = clamp( abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),6.0)-3.0)-1.0, 0.0, 1.0 );

    rgb = rgb*rgb*(3.0-2.0*rgb); // cubic smoothing

    return c.z * mix( vec3(1.0), rgb, c.y);
}
#else
vec3 hsv2rgb(in vec3 c)
{
    vec3 rgb = clamp( abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),6.0)-3.0)-1.0, 0.0, 1.0 );

    return c.z * mix( vec3(1.0), rgb, c.y);
}
#endif

//From Sam Hocevar: http://lolengine.net/blog/2013/07/27/rgb-to-hsv-in-glsl
vec3 rgb2hsv(vec3 c)
{
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

//Linear interpolation between two colors in normalized (0..1) HSV space
vec3 lerpHSV(in vec3 a, in vec3 b, in float x)
{
    float hue = (mod(mod((b.x-a.x), 1.) + 1.5, 1.)-0.5)*x + a.x;
    return vec3(hue, mix(a.yz, b.yz, x));
}

//---------------Improved RGB--------------

/*
The idea behind this function is to avoid the low saturation area in the
rgb color space. This is done by getting the direction to that diagonal
and displacing the interpolated    color by it's inverse while scaling it
by saturation error and desired lightness.

I find it behaves very well under most circumstances, the only instance
where it doesn't behave ideally is when the hues are very close    to 180
degrees apart, since the method I am using to find the displacement vector
does not compensate for non-curving motion. I tried a few things to
circumvent this problem but none were cheap and effective enough..
*/

//Changes the strength of the displacement
#define DSP_STR 1.5

//Optimizaton for getting the saturation (HSV Type) of a rgb color
#if 0
float getsat(vec3 c)
{
    c.gb = vec2(max(c.g, c.b), min(c.g, c.b));
    c.rg = vec2(max(c.r, c.g), min(c.r, c.g));
    return (c.r - min(c.g, c.b)) / (c.r + 1e-7);
}
#else
//Further optimization for getting the saturation
float getsat(vec3 c)
{
    float mi = min(min(c.x, c.y), c.z);
    float ma = max(max(c.x, c.y), c.z);
    return (ma - mi)/(ma+ 1e-7);
}
#endif

//Improved rgb lerp
vec3 iLerp(in vec3 a, in vec3 b, in float x)
{
    //Interpolated base color (with singularity fix)
    vec3 ic = mix(a, b, x) + vec3(1e-6,0.,0.);
    //Saturation difference from ideal scenario
    float sd = abs(getsat(ic) - mix(getsat(a), getsat(b), x));
    //Displacement direction
    vec3 dir = normalize(vec3(2.*ic.x - ic.y - ic.z, 2.*ic.y - ic.x - ic.z, 2.*ic.z - ic.y - ic.x));
    //Simple Lighntess
    float lgt = dot(vec3(1.0), ic);
    //Extra scaling factor for the displacement
    float ff = dot(dir, normalize(ic));
    //Displace the color
    ic += DSP_STR*dir*sd*ff*lgt;
    return clamp(ic,0.,1.);
}

vec3 hsb2rgb(in vec3 hsb)
{
    vec3 rgb = clamp(abs(mod(hsb.x*6.0+vec3(0.0, 4.0, 2.0), 6.0)-3.0)-1.0, 0.0, 1.0);
    rgb = rgb*rgb*(3.0-2.0*rgb);
    return hsb.z * mix(vec3(1.0), rgb, hsb.y);
}

//--------------------------------------GRADIENT-----------------------------------
//--------------------------------color point array logic--------------------------
//-------------------------------------by Krabcode---------------------------------

struct colorPoint
{
    float pos;
    vec4 val;
};

colorPoint emptyColorPoint()
{
    return colorPoint(1., vec4(1.,0.,0.,1.));
}

float map(float value, float start1, float stop1, float start2, float stop2)
{
    return start2 + (stop2 - start2) * ((value - start1) / (stop1 - start1));
}

float norm(float value, float start, float stop)
{
    return map(value, start, stop, 0., 1.);
}

vec4 lerpByBlendType(vec4 colorA, vec4 colorB, float amt, int blendType)
{
    float mixedAlpha = mix(colorA.a, colorB.a, amt);
    if(blendType == 0){ // normal lerp
        return mix(colorA, colorB, amt);
    }
    if(blendType == 1){ // normal lerp with improved saturation preservation
        return vec4(iLerp(colorA.rgb, colorB.rgb, amt), mixedAlpha);
    }
    if(blendType == 2){ // lerp between hues
        return vec4(hsv2rgb(lerpHSV(rgb2hsv(colorA.rgb), rgb2hsv(colorB.rgb), smoothstep(0.0, 1.0, amt))), mixedAlpha);
    }
    return vec4(0,0,0,1);
}

int findClosestLeftNeighbourIndex(float pos, colorPoint[colorsPerGradient] gradient)
{
    for(int i = 0; i < 100; i++){
        if(pos >= gradient[i].pos && pos <= gradient[i+1].pos){
            return i;
        }
        if(i >= gradient.length()){
            return 0;
        }
    }
    return 0;
}

vec4 gradientColorAt(float normalizedPos, colorPoint[colorsPerGradient] gradient, int blendType)
{
    float pos = clamp(normalizedPos, 0., 1.);
    int leftIndex = findClosestLeftNeighbourIndex(pos, gradient);
    int rightIndex = leftIndex + 1;
    colorPoint A = gradient[leftIndex];    
    colorPoint B = gradient[rightIndex];
    float normalizedPosBetweenNeighbours = norm(pos, A.pos, B.pos);
    vec4 mixedColor = lerpByBlendType(A.val, B.val, normalizedPosBetweenNeighbours, blendType);
    return mixedColor;
}

// hexToRgb from here: https://stackoverflow.com/questions/22895237/hexadecimal-to-rgb-values-in-webgl-shader
vec3 hexToRgb(int color)
{
    float rValue = float(color / 256 / 256);
    float gValue = float(color / 256 - int(rValue * 256.0));
    float bValue = float(color - int(rValue * 256.0 * 256.0) - int(gValue * 256.0));
    return vec3(rValue / 255.0, gValue / 255.0, bValue / 255.0);
}

/** example gradient

    colorPoint[colorsPerGradient] gradient = colorPoint[](
        colorPoint(0.,  vec4(hexToRgb(0x2a3d66), 1.)),
        colorPoint(0.25,vec4(hexToRgb(0x5d54a4), 1.)),
        colorPoint(0.5, vec4(hexToRgb(0x9d65c9), 1.)),
        colorPoint(1.,vec4(hexToRgb(0xd789d7), 1.))
    );

*/

float sdBox( in vec2 p, in vec2 b )
{
    vec2 d = abs(p)-b;
    return length(max(d,0.0)) + min(max(d.x,d.y),0.0);
}

float sdCircle( vec2 p, float r )
{
    return length(p) - r;
}

// Hash without Sine by David Hoskins
float hash13(vec3 p3)
{
    p3  = fract(p3 * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

float render(vec2 uv){
    float d = length(uv)*1.5;
    float angle = cos(16.*atan(uv.y, uv.x));
    float pct = (d+.01)*angle;
    float count = 60.;
    for(float i = 0.; i < count; i++){
        vec2 size = vec2(i * (1. / count) + t);
        pct -= .01*sdCircle(uv, size.x);
    }
     return pct;   
}

float renderAA(vec2 uv){
    float pixelThird = (1./resolution.x) / 3.0;
    vec2 aa = vec2(-pixelThird, pixelThird);
    float c1 = render(uv+aa.xx);
    float c2 = render(uv+aa.xy);
    float c3 = render(uv+aa.yx);
    float c4 = render(uv+aa.yy);
    return (c1+c2+c3+c4) / 4.;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - .5* resolution.xy) / resolution.y;
    colorPoint[colorsPerGradient] gradient = colorPoint[](
        colorPoint(0.0,  vec4(hexToRgb(0x2d4059), 1.)),
        colorPoint(0.5,vec4(hexToRgb(0xea5455), 1.)),
        colorPoint(0.6, vec4(hexToRgb(0xf07b3f), 1.)),
        colorPoint(0.8,  vec4(hexToRgb(0xffd460), 1.)),
        colorPoint(1.,  vec4(hexToRgb(0x2d4059), 1.))
    );
    float pct = renderAA(uv);
    pct = mod(pct, 1.);
    pct += .05 * hash13(vec3(1000. * uv, .01 * t));
    glFragColor = gradientColorAt(pct, gradient, 0);
}

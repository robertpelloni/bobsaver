#version 420

// original https://www.shadertoy.com/view/MlGcDw

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Mandelbrot Set in GLSL
// Created by John Lynch - Sep 2018;
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

const float PI = 3.141592653589793234;
const float SCALE_PER_FRAME = 1.003;
const vec4 white = vec4(1., 1., 1., 1.);
const vec4 black = vec4(0., 0., 0., 1.);
const vec4 orange = vec4(1.0, 0.4, 0., 1.);
const vec4 cyan = vec4(0., 0.4, 1.0, 1.);
const vec4 magenta = vec4(1.0, 0., 1.0, 1.);
const vec4 gold = vec4(1.0, 0.84, 0.66, 1.);

vec4[] cols = vec4[](black, gold, black, gold, black, orange, black, white, black, orange, black);
int numFirstColours = 12;
bool modifiedColours = true;

float aspectRatio;
highp vec2 zMin;    // corners of the region of the Complex plane we're looking at
highp vec2 zMax;
highp vec2 zSpan;
highp vec2 zIncr;

const float escapeRadius = 6.0;
const float escapeRadius2 = 36.0;
float exponent = 2.;
int maxIterations = 1024;

// ==================================================================
// Some functions stolen and adapted from Github - 
// https://github.com/tobspr/GLSL-Color-Spaces/blob/master/ColorSpaces.inc.glsl
// - not tested!

vec3 hue2rgb(float hue)
{
    float R = abs(hue * 6. - 3.) - 1.;
    float G = 2. - abs(hue * 6. - 2.);
    float B = 2. - abs(hue * 6. - 4.);
    return clamp(vec3(R,G,B), 0., 1.);
}

// Converts a value from linear RGB to HCV (Hue, Chroma, Value)
vec3 rgb2hcv(vec3 rgb) {
    // Based on work by Sam Hocevar and Emil Persson
    vec4 P = (rgb.g < rgb.b) ? vec4(rgb.bg, -1.0, 2.0/3.0) : vec4(rgb.gb, 0.0, -1.0/3.0);
    vec4 Q = (rgb.r < P.x) ? vec4(P.xyw, rgb.r) : vec4(rgb.r, P.yzx);
    float C = Q.x - min(Q.w, Q.y);
    float H = abs((Q.w - Q.y) / (6. * C + 1.e-10) + Q.z);
    return vec3(H, C, Q.x);
}

// Converts from HSL to linear RGB
vec3 hsl2rgb(vec3 hsl) {
    vec3 rgb = hue2rgb(hsl.x);
    float C = (1. - abs(2. * hsl.z - 1.)) * hsl.y;
    return (rgb - 0.5) * C + hsl.z;
}

// Converts from linear rgb to HSL
vec3 rgb2hsl(vec3 rgb) {
    vec3 HCV = rgb2hcv(rgb);
    float L = HCV.z - HCV.y * 0.5;
    float S = HCV.y / (1. - abs(L * 2. - 1.) + 1.e-10);
    return vec3(HCV.x, S, L);
}

// ======================== USEFUL FUNCTIONS ========================
void updateGeometryVars() {
    zSpan = zMax - zMin;
    zIncr = zSpan / resolution.xy;
}

vec2 xyToPixel(vec2 z, vec2 zMin, vec2 zMax) {
    return (z - zMin) / (zMax - zMin) * resolution.xy;
}

vec2 pixelToXy(vec2 pixel, vec2 zMin, vec2 zMax) {
    return pixel / resolution.xy * (zMax - zMin) + zMin;
}

void scale(float factor) {
    highp vec2 halfDiag = (zMax - zMin) / 2.0;
    highp vec2 centre = zMin + halfDiag;
    zMin = centre - halfDiag / factor;
    zMax = centre + halfDiag / factor;
    updateGeometryVars();
}

// some complex functions for later use...
float modc(vec2 z) {
    return length(z);
}

float arg(vec2 z) {
    return atan(z.y, z.x);
}

vec2 polar(float r, float phi) {
    return vec2(r * cos(phi), r * sin(phi));
}

vec2 boxFold(vec2 z, float fold) {
    return vec2(z.x > fold ? 2. * fold - z.x : (z.x < -fold ? -2. * fold - z.x : z.x),
                z.y > fold ? 2. * fold - z.y : (z.y < -fold ? -2. * fold - z.y : z.y));
}

vec2 ballFold(vec2 z, float r, float bigR) {
    float zAbs = modc(z);
    r = abs(r);
    return zAbs < r ? z / (r * r) : (zAbs < abs(bigR)) ?
            z / (zAbs * zAbs)
            : z;
}

// ======================= The functions to iterate ======================

highp vec2 f0(vec2 z, vec2 w) {
    return vec2(z.x * z.x - z.y * z.y, 2. * z.x * z.y) + w;
}

highp vec2 f7(vec2 z, vec2 w) {
    return polar(PI * cos(z.x) * cos(z.y), arg(z));
}

// ======================= The grindstone ================================
float iterate(vec2 z) {
    int numIts = 0;
    float realIts = 0.;
    vec2 z0 = z;
    float zAbs = z.x * z.x + z.y * z.y;
    float zAbsPrevious = zAbs;
    while (numIts < maxIterations && zAbs < escapeRadius) {
        numIts++;
        // >>>>>>>>>>>>>>>>>>>>>>>>>>>>
        z = f0(z, z0);
        // <<<<<<<<<<<<<<<<<<<<<<<<<<<<
        zAbsPrevious = zAbs;
        zAbs = z.x * z.x + z.y * z.y;
    }
    if (zAbs < escapeRadius) {
        realIts = float(numIts + 1) - (log(log(zAbs + 1.) + 1.) / log(log(escapeRadius + 1.) + 1.));
    }
    else {
        float far = max(exponent, log(zAbs) / log(zAbsPrevious));
        realIts = float(numIts) - (log(log(zAbs)) - log(log(escapeRadius))) / log(far);
    }
    return ++realIts;
}

void main(void) {
    // I'd like to declare these three outside of this main method, but can't find a 
    // way to keep the compiler happy. :(
    aspectRatio = resolution.x / resolution.y;
    zMin = vec2(-1.2 * aspectRatio - 1.6, -1.2);    // corners of the region of the Complex plane we're looking at
    zMax = vec2(1.2* aspectRatio - 1.6, 1.2);
        
    scale(pow(SCALE_PER_FRAME, float(frames)));
           
    vec2 z = pixelToXy(gl_FragCoord.xy, zMin, zMax);
    float its = iterate(z);
    float nfc = float(numFirstColours);
    float colourMappingFactor = (nfc - 1.) / float(maxIterations); 
    
    float colourIndex = modifiedColours ? mod(its, nfc) : mod(its * colourMappingFactor, nfc); // map iteration count to a colour
    int firstColourIndex = int(floor(colourIndex));
    float interpolationFactor = mod(colourIndex, 1.);
    
    // Slight precautionary hack!    Or let's call it clamping!
    if (firstColourIndex >= numFirstColours) {
        firstColourIndex = numFirstColours - 1;
        interpolationFactor = 1.;
    }    
    if (firstColourIndex < 0) {
        firstColourIndex = 0;
    }

    vec4 col = mix(cols[firstColourIndex], cols[int(mod(float(firstColourIndex + 1), float(cols.length())))], interpolationFactor);
    if (time > 60.) {
        col -= vec4(0.1, 0.1, 0.1, 0.00) * (time - 60.0);  // fade when losing resolution 
        
    }
    // Change hue...
    vec3 c = rgb2hsl(col.rgb);
    c.s = mod(c.s - time / 21., 1.0);    // so hue rotates the entire 360 deg  ~thrice in 64 seconds
    col = vec4(hsl2rgb(c), 1.);    
    // ===========================================================
    
    glFragColor = col;
}

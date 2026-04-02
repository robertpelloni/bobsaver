#version 420

// original https://www.shadertoy.com/view/cdBXDy

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define FREQUENCY_XY          0.2
#define FREQUENCY_Z           0.04
#define AMPLITUDE_X           2.0
#define AMPLITUDE_Y           2.0
#define AMPLITUDE_XY_SCALE    0.15
#define AMPLITUDE_Z           1.5

// Norm to use for divergence
// P = 2.0 is the typical "smooth" version
// P = 1.0 is lumpy, which looks cooler
//     but it's maybe not strictly correct!
#define P                     1.0
#define THRESHOLD             2.0

#define TAU 6.28318530718
#define DEPTH 50

// Allow for mouse to change XY camera position
#define INTERACTIVE 0

// --------------------------------------------------------
// Some stuff copied from elsewhere

// "Will it blend" by nmz
// https://www.shadertoy.com/view/lsdGzN
vec3 hsv2rgb( in float h, in float s, in float v ) {
    vec3 rgb = clamp( abs(mod(h*6.0+vec3(0.0,4.0,2.0),6.0)-3.0)-1.0, 0.0, 1.0 );
    rgb = rgb*rgb*(3.0-2.0*rgb); // cubic smoothing    
    return v * mix( vec3(1.0), rgb, s);
}

// "matplotlib colormaps" by mattz
// https://www.shadertoy.com/view/WlfXRN
vec3 viridis(float t) {
    const vec3 c0 = vec3(0.2777273272234177, 0.005407344544966578, 0.3340998053353061);
    const vec3 c1 = vec3(0.1050930431085774, 1.404613529898575, 1.384590162594685);
    const vec3 c2 = vec3(-0.3308618287255563, 0.214847559468213, 0.09509516302823659);
    const vec3 c3 = vec3(-4.634230498983486, -5.799100973351585, -19.33244095627987);
    const vec3 c4 = vec3(6.228269936347081, 14.17993336680509, 56.69055260068105);
    const vec3 c5 = vec3(4.776384997670288, -13.74514537774601, -65.35303263337234);
    const vec3 c6 = vec3(-5.435455855934631, 4.645852612178535, 26.3124352495832);
    return c0+t*(c1+t*(c2+t*(c3+t*(c4+t*(c5+t*c6)))));
}

// "complex exponentiation" by stduhpf
// https://www.shadertoy.com/view/MdKBWd
vec2 toPol(vec2 a){
    return vec2(length(a),atan(a.y,a.x));
}
vec2 toAlg(vec2 a){
    return a.x*vec2(cos(a.y),sin(a.y));
}

vec2 cpow(vec2 a, vec2 b){
     a = toPol(a);
    return toAlg(vec2(pow(a.x,b.x)*exp(-b.y*a.y),b.y*log(a.x)+b.x*a.y));
}

// --------------------------------------------------------
// Original stuff from here on
vec2 cmult(vec2 z1, vec2 z2) {
    return vec2(
        z1.x*z2.x - z1.y*z2.y,
        z1.x*z2.y + z1.y*z2.x
    );
}
vec2 rot(float ang) {
    return vec2(cos(ang), sin(ang));
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv.x = (uv.x - 0.5) * resolution.x / resolution.y + 0.5;
    
    vec3 cam;
    // float P = 1.0 + (1.0 + tanh(20.0*sin(time * TAU * FREQUENCY_Z * 2.0)))/2.0;
    
    #if (INTERACTIVE == 0)
    cam = vec3(
        rot(TAU * FREQUENCY_XY * time) * AMPLITUDE_XY_SCALE * vec2(AMPLITUDE_X, AMPLITUDE_Y),
        1.0 + AMPLITUDE_Z*pow(sin(TAU * FREQUENCY_Z * time), 2.0)
    );
    #else
    cam = vec3(
        -(mouse*resolution.xy.xy / resolution.xy - 0.5)*10.0*AMPLITUDE_XY_SCALE,
        1.0 + AMPLITUDE_Z*pow(sin(TAU * FREQUENCY_Z * time), 2.0)
    );
    #endif
    
    vec2 z0, z1, lz1;
    float l;
    vec3 col;
    bool hit = false;

    for (int layer = 0; layer <= DEPTH; layer++) { 
        z0 = (uv - 0.5) * 2.0 * 1.5 * (1.0 / cam.z) + cam.xy / (1.0 + 1.0*float(layer));
        z0.x -= 0.5;
        z0.y -= 0.0;
        z1 = z0;
        lz1 = vec2(0.0, 0.0);
        col = vec3(0.0, 0.0, 0.0);
        l = 0.0 - 0.5*(cam.z - 1.0);
        
        // Skip computation inside main cardioid and bulb
        //   https://iquilezles.org/articles/mset1bulb
        //   https://iquilezles.org/articles/mset2bulb
        float z2 = dot(z1, z1);
        if( 256.0*z2*z2 - 96.0*z2 + 32.0*z1.x - 3.0 < 0.0 ) continue;
        if( 16.0*(z2+2.0*z1.x+1.0) - 1.0 < 0.0 ) continue;
        
        float p = THRESHOLD;
        for (int i = 0; i <= layer; i++) {
            // use L2 norm on first layer to avoid covering the main bulb spikes
            p = i == 0 ? THRESHOLD : 1.0; 
            z1 = cpow(z1, vec2(2.0, 0.0)) + z0;
            l += pow(cam.z, 0.5)*length(z1 - lz1);
            //#if LUMPY
            //if (i == layer && length(z1) >= 2.0) {
            if (i == layer && (pow(abs(z1.x), p) + pow(abs(z1.y),p)) >= pow(THRESHOLD, p)) {
                // Color by length using Viridis
                l += pow(float(layer), 1.0);
                col = exp(-l*0.05)*viridis(pow(log(1.0 + 1.5/l), 0.8));
                // Color by length using grayscale
                //col = exp(-l*0.1) * vec3(1.0, 1.0, 1.0);
                hit = true;
                break;
            }
            lz1 = z1;
        }
        if (hit) break;
    }
    
       
    // Output to screen
    glFragColor = vec4(col,1.0);
}

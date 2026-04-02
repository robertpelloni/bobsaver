#version 420

// original https://www.shadertoy.com/view/Xltfz2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.1415926535897932384626433832795
#define PHI 1.6180339887498948482

mat2 rotate(float theta) {
    mat2 m = mat2(cos(theta), sin(theta),
                  -sin(theta), cos(theta)
                 );
    return m;
}

float sinStep(float x, float w) {
    float y = (x+(1./w)*sin(w*x));
    return y;
}
    
float sinc(float x, float w) {
    float y = sin(w*x)/(w*x);
    return y;
}

float gaussianWindow1D(float x) {
    return exp(-(x*x));
}

float gaussianWindow2D(vec2 uv) {
    return exp(-(uv.x*uv.x+uv.y*uv.y));
}

float absPolyWindow(float x, float p) {
    return 1.-pow(abs(x),p);
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (-1.+2.*(gl_FragCoord.xy/resolution.xy))*(resolution.xy/resolution.yy);
    
    float f = PI;
    float theta = 0.25*f*sinStep(time,f);
    uv *= rotate(theta);
    
    float df = distance(vec2(0.,0.), uv.xy);
        
    vec3 colOffset = (1.-df)*1.75*vec3(0.,1.,2.)*(0.5+0.5*cos(PI/2.+1.*f*time+0.25*f*sin(f*time)));
    
    //float win = clamp((1.-pow(df, 4.)),0.,1.);
       float win = gaussianWindow1D(uv.y+uv.x);
    
    float sum = 0.;
    float a = 0.;
    float m = 16.;
    float zoom = (0.75-0.25*cos(f*time));
    vec3 col = vec3(0.,0.,0.);
    
    for (float i=1.; i<64.; i++) {
        a = (1./i)*(1.+(sinc(time,PI*i*m)))*0.5;
        sum += a;
        col += a*cos(f*((2.+cos(time*f/2.))+i*sinStep(time, f))+(16.*i*exp((2.*(uv.x*uv.y)*zoom))+colOffset));
    }
    
    col = (1.+col)*(1./sum)*win;
    // Output to screen
    glFragColor = vec4(1.-col,1.0);
}


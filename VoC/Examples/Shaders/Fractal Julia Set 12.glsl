#version 420

// original https://www.shadertoy.com/view/3tdyRr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float pi = 4.*atan(1.);

mat2 rotate(float a) {
    float c = cos(a);
    float s = sin(a);
    return mat2(c,s,-s,c);
}

vec2 cmult(in vec2 a, in vec2 b) {
    return vec2(a.x * b.x - a.y * b.y, a.y * b.x + a.x * b.y);
}

float wrap(float x, float a) {
    return x - a*floor(x/a);
}

vec2 f(vec2 z) {
    float a = pi/4.0 + time/15.0;
    vec2 c = 0.7885*vec2(cos(a), sin(a));
    return (cmult(z,z) + c);
}

// Smooth HSV to RGB conversion 
vec3 hsv2rgb_smooth( in vec3 c )
{
    vec3 rgb = clamp( abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),6.0)-3.0)-1.0, 0.0, 1.0 );

    rgb = rgb*rgb*(3.0-2.0*rgb); // cubic smoothing    

    return c.z * mix( vec3(1.0), rgb, c.y);
}

float R = 1.6;

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (1.35)*(2.*gl_FragCoord.xy-resolution.xy)/resolution.y;

    vec2 z = uv;

    float max_iter = 1000.;
    float iter = 0.;
    while((iter < max_iter) && (length(z) < R)) {
        z = f(z);
        iter = iter + 1.;
    }
    if (iter < max_iter) {
        // renormalization
        iter = iter + 1. - log(log2(length(z)));
    }
    
    // HSV coloring
    float h = iter/max_iter; //atan(z.y, z.x);
    float r = log(1.+length(z));
    float s = (1.+sin(2.0*pi*r))/2.;
    float v = 1.;
    if(iter > max_iter) {
         v = 0.;
    }
    vec3 hsv = hsv2rgb_smooth(vec3(h,s,v));
    
    vec3 black = vec3(0);
    vec3 icol = vec3(wrap(float(iter),100.)/10.*hsv);
    vec3 col = (iter == max_iter)?black:icol;

    // Output to screen
    glFragColor = vec4(col,1.0);
}

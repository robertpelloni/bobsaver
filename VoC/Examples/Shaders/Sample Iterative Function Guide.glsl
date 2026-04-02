#version 420

// original https://www.shadertoy.com/view/3tyfWt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Evan Nave 2021
// Iterative Functions in GLSL: https://www.shadertoy.com/view/MtBGDW
//
// 'Mythic Bird' Graph: http://www.atomosyd.net/spip.php?article98
// 'Tinkerbell map': https://en.wikipedia.org/wiki/Tinkerbell_map
// 'Ikeda map': https://en.wikipedia.org/wiki/Ikeda_map
// 'Bogdanov map': https://en.wikipedia.org/wiki/Bogdanov_map
// 'Mandelbrot Set': https://en.wikipedia.org/wiki/Mandelbrot_set
// 'Lorenz Strange Attractor': https://en.wikipedia.org/wiki/Lorenz_system
// 
///////////////////////////
// 
// This a compilation of examples of iterative functions.
// The basic premise of iterative functions is that the current
// value of x, y, or both, affect the next values.
// 
// Some of these examples are attractors. Attractors are functions
// or fields where values drift toward a point or set of points. This
// can lead to pleasing or interesting visuals. Enjoy!
// 
///////////////////////////
// General Structure of an Iterative Function:
// 
// ITERATIONS : Number of steps a function will take
// BREAK : The value at which the length/distance of a function escapes
// 
// float w : increments if function is within BREAK value
// 
// Other Parameters: These examples come with a set of parameter values
//                   that come with the curve. Please see the references
//                   at the top if you are curious about what they do!
// 
// funct(position, time){
//     
//     for(int i = 0; i < ITERATIONS; i++){
//         x[n+1] = ...;
//         y[n+1] = ...;
//         if(length(xy) > BREAK)break;
//         x[n] = x[n+1];
//         y[n] = y[n+1];
//     }
//     return w/ITERATIONS;
// }
// 

#define SCALE 3.
#define ITERATION 80
#define PI 3.14159265359

////////////////////////////////////
// Mythic Bird Example (THE QUASI-CONSERVATIVE GUMOWSKI-MIRA MAP)
// 
// g(x,u) = ux + (2(1 - u)x^2/(1 + x^2))
// 
// x[n+1] = y[n] + g(x[n],u) + a(1 - by[n]^2)y[n]
// y[n+1] = -x[n] + g(x, u)
//
float g(float x, float u){
    return u*x + ((2.*(1. - u)*pow(x, 2.)) / (1. + pow(x, 2.)));
}

vec2 mythic(vec2 c,float t){
    vec4 z = vec4(c.x*1.6, -c.y, 0.0, 0.0);
    vec3 zi = vec3(0.0);
    
    float a = 0.0009;
    float b = 0.005 - 0.5;
    float u = -0.801;
    
    u += cos(t*0.1 + 15.7)*0.25 + 0.25;
    
    float m = -3.5;
    
    float BREAK = 30.0;
    
    for(int i=0; i<ITERATION; i++){
        zi.x = z.y + g(z.x, u) + a*z.y*(1. - b*pow(z.y, 2.) + m);
        zi.y = -z.x + g(zi.x, u);
        if(length(zi.xy) > BREAK)break;
        z.w++;
        z.xyz=zi;
        z.z = float(i);
    }
    z.w/=float(ITERATION);
    return 1.0-z.wx;
}

////////////////////////////////////
// Bogdanov Map Example
//
// x[n+1] = x[n] + y[n+1]
// y[n+1] = y[n] + ey[n] + kx[n](x[n] - 1) + ux[n]y[n]
//
vec2 bogdanov(vec2 c,float t){
    vec4 z = vec4(c.x, c.y, 0.0, 0.0);
    vec3 zi = vec3(0.0);
    
    float e = 0.02;
    float k = 1.2 + cos(t);
    float u = 0.0;
    
    float BREAK = 1.0;
    
    for(int i=0; i<ITERATION; i++){
        zi.y = z.y + e*z.y + k*z.x*(z.x - 1.) + u*z.x*z.y;
        zi.x = z.x + zi.y;
        if(length(zi.xy) > BREAK)break;
        z.w++;
        z.xyz=zi;
        z.z = float(i);
    }
    z.w/=float(ITERATION);
    return 1.0-z.wx;
}

////////////////////////////////////
// Tinker Bell Example
//
// x[n+1] = x[n]^2 - y[n]^2 + ax[n] + by[n]
// y[n+1] = 2x[n]y[n] + cx[n] + dy[n]
//
vec2 tinker(vec2 p,float t){
    vec4 z = vec4(p.x, p.y, 0.0, 0.0);
    vec3 zi = vec3(0.0);
    
    float a = 0.1;
    float b = -.6013 + cos(t);
    float c = 2.0;
    float d = 0.5 + cos(t);
    
    float BREAK = 5.0;
    
    for(int i=0; i<ITERATION; i++){
        zi.x = pow(z.x, 2.0) - pow(z.y, 2.0) + a*z.x + b*z.y;
        zi.y = 2.*z.x*z.y + c*z.x + d*z.y;
        if(length(zi.xy) > BREAK)break;
        z.w++;
        z.xyz=zi;
        z.z = float(i);
    }
    z.w/=float(ITERATION);
    return 1.0-z.wx;
}

////////////////////////////////////
// Ikeda Map Example
//
// t[n] = 0.4 - (6 / (1 + x[n]^2 + y[n]^2))
//
// x[n+1] = 1 + u(x[n]cos(t[n]) - y[n]sin(t[n]))
// y[n+1] = u(x[n]sin(t[n]1) + y[n]cos(t[n]))
//
vec2 ikeda(vec2 c,float t){
    vec4 z = vec4(c.x, c.y, 0.0, 0.0);
    vec3 zi = vec3(0.0);
    
    float u = 0.918 + cos(t)*0.25 + 0.45;
    float tn = 0.0;
    
    float BREAK = 1.9;
    
    for(int i=0; i<ITERATION; i++){
        tn = 0.4 - (6. / (1. + pow(z.x, 2.0) + pow(z.y, 2.0)));
        
        zi.x = 1. + u*(z.x*cos(tn) - z.y*sin(tn));
        zi.y = u*(z.x*cos(tn) + z.y*sin(tn));
        
        if(length(zi.xy) > BREAK)break;
        z.w++;
        z.xyz=zi;
        z.z = float(i);
    }
    z.w/=float(ITERATION);
    return 1.0-z.wx*10.;
}

////////////////////////////////////
// Mandelbrot Set Example (From: https://www.shadertoy.com/view/MtBGDW)
//
// x[n+1] = x[n]^2 - y[n]^2
// y[n+1] = 2(x[n]y[n])
//
vec2 mandelbrot(vec2 c,float t){
    vec4 z = vec4(c, 0., 0.);
    vec3 zi = vec3(0.0);
    for(int i=0; i<ITERATION; ++i){
        zi.x = (z.x*z.x-z.y*z.y);
        zi.y = 2.*(z.x*z.y);
        zi.xy += c;
        if(dot(z.xy,z.xy)>4.0)break;
        z.w++;
        z.xyz=zi;
    }
    z.w/=float(ITERATION);
    return 1.0-z.wx;
}

////////////////////////////////////
// Lorenz Strange Attractor (2D Projection)
//
// dx = s(y - x)
// dy = x(r - z) - y
// dz = xy - bz
//
float drawdot(vec2 uv, float r){
    return smoothstep(0.0, 0.01, length(uv) - r);
}

float lorenz(vec2 c,float t){
    vec4 p = vec4(0.1, 0., 0., 0.);
    vec3 d = vec3(0.);
    
    float s = 10.;
    float r = 28.;
    float b = 8./3.;
    
    float dt = 0.02;
    
    //Animation
    dt *= (cos(t*0.1)*0.0015 + 0.5);
    
    for(int i=0; i<ITERATION*10; i++){
        d.x = (s * (p.y - p.x))*dt;
        d.y = (p.x * (r - p.z) - p.y)*dt;
        d.z = (p.x * p.y - b * p.z)*dt;
        p.xyz += d;
        p.w += drawdot(c + 0.02*p.xy, 0.004);
    }
    p.w/=float(ITERATION*10);
    
    p.w = smoothstep(0.995, 1.0, p.w);
    
    return p.w;
}

////////////////////////////////////
// MAIN IMAGE
void main(void) {
    vec2 uv = (2.0*gl_FragCoord.xy-resolution.xy)/resolution.y;
    uv *= SCALE;
    vec3 col = vec3(0.);
    
    //Mythic Bird
    float mb = max(mythic((uv + vec2(3.5, -1.5))*13.0,time).x, 0.);
    
    //Bodganov Map
    mb *= max(bogdanov((uv + vec2(3.5, 1.2))*0.8,time).x, 0.);
    
    //Tinker Bell Attractor
    mb *= max(tinker((uv + vec2(0.0, -1.6))*1.5,time).x, 0.);
    
    //Ikeda Attractor
    mb *= ikeda((uv + vec2(0.0, 1.8))*3.0,time).x;
    
    //Mandelbrot Set
    mb *= mandelbrot((uv + vec2(-3.9, -1.4))*0.9,time).x;
    
    //Lorenz Strange Attractor
    mb *= max(lorenz((uv + vec2(-3.5, 1.3))*0.4,time), 0.);
    
    mb = 1.0 - mb;
    col = vec3(mb);
    
    glFragColor = vec4(col, 1.0);
}

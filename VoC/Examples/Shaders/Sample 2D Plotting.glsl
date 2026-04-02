#version 420

// original https://www.shadertoy.com/view/WtfBzN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/* Created by Nikita Miropolskiy, nikat/2020

    inspired by this shader https://www.shadertoy.com/view/4scSz4

 */

vec3 colBackground1 = vec3( 0.92, 0.96, 0.9);
vec3 colBackground2 = vec3( 0.87, 0.93, 0.83);
vec3 colAxes        = vec3( 0.1,  0.1,  0.1);
vec3 colNaive       = vec3( 0.5,  0.0,  0.5);
vec3 colDerivative  = vec3( 0.1,  0.0,  0.7);
vec3 colSampling    = vec3( 0.7,  0.0,  0.0);

// This is a function that we want to plot.
float f(float x) {
    //return sin(x);
    return sin(10.0*sin(time*0.33) + 3.0*x*sin(x));
}

// This is the algebraic derivative of f function
// for example go to www.wolframalpha.com and search "sin(c + 3.0*x*sin(x))'"
//float df(float x) {
//    return 3.0*(sin(x) + x*cos(x))*cos(10.0*sin(time*0.33) + 3.0*x*sin(x));
//}

vec2 frag2point(in vec2 frag) {
    return 4.0*(frag - 0.5*resolution.xy)/resolution.yy;
}

float samples2stroke(float ratio) {
    return 1.0 - smoothstep(0.0, 0.5, ratio)*smoothstep(1.0, 0.5, ratio);
}

void main(void)
{
    // draw grid
    vec2 p = frag2point(gl_FragCoord.xy);
    vec3 col = mix(colBackground1, colBackground2, mod(floor(p.x)+floor(p.y), 2.0));
    
    // naive comparison
    float epsilon = 0.01;
    float plotNaive = smoothstep(0.0, 2.0*epsilon, abs(p.y - f(p.x)));
    
    // algebraic derivative calculation
    // float dy = df(p.x);
    
    // numeric derivative calculation
    float dy = (f(p.x+epsilon*0.5)-f(p.x-epsilon*0.5))/epsilon;
    
    // comparsion with derivative correction
    float plotDerivative = smoothstep(0.0, 2.0*epsilon*sqrt(1.0+dy*dy), abs(p.y - f(p.x)));
    
    // sampling
    float pixSample = 0.5;
    float pixWidth = 1.0;
    float plot = 0.0, axes = 0.0;
    float total = 0.0;
    for (float sx = gl_FragCoord.xy.x-pixWidth; sx <= gl_FragCoord.xy.x+pixWidth; sx += pixSample) {
        for (float sy = gl_FragCoord.xy.y-pixWidth; sy <= gl_FragCoord.xy.y+pixWidth; sy += pixSample) {
            total++;
            vec2 s = frag2point(vec2(sx, sy));
            if ( f(s.x) > s.y ) plot++;
            if ( s.x*s.y > 0.0 ) axes++;            
        }
    }
    float plotAxes = samples2stroke(axes/total);
    float plotSampling = samples2stroke(plot/total);
    
    // draw axes
    col = mix(colAxes, col, plotAxes);
    
    // draw plot depending on gl_FragCoord.xy.x
    if (gl_FragCoord.xy.x < 0.33*resolution.x) {
        // naive approach
        col = mix(colNaive, col, plotNaive);
    } else if (gl_FragCoord.xy.x < 0.67*resolution.x)  {
        // derivative calculation
           col = mix(colDerivative, col, plotDerivative);
    } else {
        // sampling
        col = mix(colSampling, col, plotSampling);
    }
    
    // vignetting    
    col *= 1.0 - 0.1*length(p);
    
    // output
    glFragColor = vec4(col, 1.0);  
}

#version 420

// original https://www.shadertoy.com/view/wlcGD4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Created by Logos (Robert Śmietana) - 14.12.2019, Bielsko-Biała, Poland.

void main(void)
{

    //--- calculate point coordinates ---//
    
    vec2 cartesian = (2.0*gl_FragCoord.xy - resolution.xy) / resolution.y;
    vec2 polar = vec2(atan(cartesian.y, cartesian.x) + 0.057*time, mod(log(length(cartesian)), 0.2));
    
    float l = length(cartesian);
    float s = sin(12.0*polar.x);
    
    float d;

    
    //--- measure first sinus ---//
    
    vec2 sinus1 = polar;
    sinus1.y += 0.08 * s;
    
    d = abs(sinus1.y - 0.1);    
    
    
    //--- measure second sinus ---//
    
    vec2 sinus2 = polar;
    sinus2.y -= 0.08 * s;
    
    d = min(d, abs(sinus2.y - 0.1));

    
    //--- measure eye --//
    
    vec2 eye = polar;
    eye.x = mod(eye.x, 3.1415926535 / 12.0);
    
    d = min(d, length(eye - vec2(0.135, 0.1)) - 0.035  - 0.025*sin(time - 6.0*l));

    //--- calculate final pixel color ---//
                  
    vec3 outputColor = vec3(0.5 - 0.5*cos(polar.x + time), 
                               0.6 - 0.07*sin(polar.x - 0.22*time),
                            0.5 - 0.5*sin(polar.x - time));

    outputColor *= 1.0 - exp(-45.0*abs(d));
    outputColor *= 0.8 + 0.2*cos(240.0*d);
    outputColor = l * mix(vec3(1.0), outputColor, smoothstep(0.0, 0.0142, abs(d)));

    glFragColor = vec4(outputColor, 1.0);
                  
}

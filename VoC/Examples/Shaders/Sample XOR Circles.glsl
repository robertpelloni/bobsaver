#version 420

// original https://www.shadertoy.com/view/4dSGDR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define BAND_SPACING 0.5

void main(void)
{
    //divide by .yy to get an unstretched circle
    vec2 uv = -1.0 + 2.0 * gl_FragCoord.xy / resolution.yy;
    
    //define the position of first circle
    float rad = length(uv);
    float m = (mod(rad - time*0.2, BAND_SPACING));
    
    //f(x) = mag(uv)
    //set color as per the first circle
    vec3 col = vec3(
                mix(0.,1., float(int(m - BAND_SPACING/2.0 + 0.99))),
                     0,
                     0.);
    
    //define position of second circle
    float r2 = length(uv - vec2(1.0+sin(time),0.0));
    float m2 = mod(r2 - (time*0.2), BAND_SPACING);
    
    //add the green channel as per the second circle
    col.y += mix(0., 1., float(int(m2 - BAND_SPACING/2.0 + 0.99))),
    
    //apply XOR
    //if in both circles, x+y == 2, so -1. will shade black
    //if only 1 circle, x+y == 1, so -1 will shade to current color
    col.xy = vec2(  mix (col.x, 0., (col.x+col.y - 1.)),
                    mix (col.y, 0., (col.x+col.y - 1.)));
        

    glFragColor = vec4(col,1.0);
}

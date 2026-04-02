#version 420

// original https://www.shadertoy.com/view/lltBWM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float wave(float x, float y) 
{
    return sin(10.0*x+10.0*y) / 5.0 +
           sin(20.0*x+15.0*y) / 3.0 +
           sin(4.0*x+10.0*y) / -4.0 +
           sin(y) / 2.0 +
           sin(x*x*y*20.0) + 
           sin(x * 20.0 + 4.0) / 5.0 +
           sin(y * 30.0) / 5.0 + 
           sin(x) / 4.0; 
    
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;

    float z = wave(uv.x, uv.y) + 2.0;
    
    
    z *= 4.0 * sin(1.57 + time / 5.0);
    float d = fract(z);
    if(mod(z, 2.0) > 1.) d = 1.-d;
     

    d = d/fwidth(z);
    glFragColor = vec4(d);

}

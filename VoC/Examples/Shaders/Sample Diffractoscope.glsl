#version 420

// original https://www.shadertoy.com/view/Wsj3Wy

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv.x = uv.x * resolution.x / resolution.y;
    float pi = 3.141592654;
    
    vec2 xy = (uv - 0.5) * 2.0;
    xy.x = xy.x -0.8;
    float radius = length(xy);
    float angle = (atan(xy.y/xy.x));
    
    float oscTime = pow(time,1.0) * cos(log(time+1.0));
    float shimmy = oscTime*cos(12.0*radius + time*2.0)*exp(-3.0*radius);
    float e_angle=angle+shimmy*0.2;
    
    float green = 0.5 + 0.5 * cos(time+angle+radius);
    
    float blue = 1.0;
    float red=abs(sin(time+angle+radius+shimmy));
    float bob=0.7 + 0.4 * sin (22.0 * pi * e_angle);
    if (radius > bob) {
        blue=0.0;red=0.0;
    }
    
    
    glFragColor = vec4(red, 0.0, blue, 0.0);

}

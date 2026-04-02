#version 420

// original https://www.shadertoy.com/view/3tfBD2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// reference:
// https://en.wikipedia.org/wiki/Mandelbrot_set

#define PI 3.1415926538
#define PI2 PI/2.0

// from: https://developer.download.nvidia.com/cg/saturate.html
vec3 saturate(vec3 x)
{
  return max(min(x, 1.0), 0.0);
}

// from: http://www.chilliant.com/rgb2hsv.html
vec3 HUEtoRGB(in float H)
{
    float R = abs(H * 6.0 - 3.0) - 1.0;
    float G = 2.0 - abs(H * 6.0 - 2.0);
    float B = 2.0 - abs(H * 6.0 - 4.0);
    return saturate(vec3(R,G,B));
}

void main(void)
{
    float aspect = resolution.x / resolution.y;
    vec2 uv = vec2(gl_FragCoord.xy.x / resolution.y, gl_FragCoord.xy.y / resolution.y);
    uv *= 2.0; // transform to [-1, 1] y domain
    uv -= vec2(aspect, 1.0); // center on screen
    //uv /= pow(2.0, time);
    uv *= 1.5;
    //uv /= pow(2.0, sin(time*PI2/18.0-PI2)*9.0+9.0);
    
    vec2 xy = vec2(0.0, 0.0);
    int i = 0;
    
    // |z| <= 2
    for (;dot(uv, uv) < 65536.0 && i < 1000; i++)
    {
        vec2 c = vec2(abs(tan(time*PI2/20.2-PI2))*0.5, abs(tan(time*PI2/30.1-PI2))*0.5);
        // z^2 + c = x^2 + 2ixy -y^2 + cx + icy
        uv = vec2(uv.x*uv.x - uv.y*uv.y, 2.0*uv.x*uv.y) + c;
    }

    glFragColor = vec4(HUEtoRGB(mod(0.5/log(float(i)), 1.0)), 1.0);
    //glFragColor = (i < 1000) ? vec4(HUEtoRGB(float(i)/1000.0), 1.0) : vec4(0.0, 0.0, 0.0, 1.0);
}

#version 420

// Mandelbrot and Julia sets
// ---------------------
// Copyright 2020 Matteo Basei
// http://www.matteo-basei.it
// https://www.youtube.com/c/matteobasei

uniform vec2 resolution;
uniform vec2 mouse;
uniform float time;

out vec4 glFragColor;

float width = 0.;
float height = 0.;

const float complexWidth = 4.0;
float zoom = 0.;
vec2 center = vec2(0.);

const int maxIterations = 100;
const float maxLength = 3.0;
const float logMaxLength = log(maxLength);
const float logTwo = log(2.0);
const vec2 zero = vec2(0.0);

const vec3 mandelbrotColor = vec3(3.0, 1.5, 1.0);    
const vec3 juliaColor = vec3(1.0, 3.0, 6.0);    
const vec3 lineColor = vec3(1.0, 1.00, 0.75);

vec2 screenToComplex(vec2 point)
{
    return zoom * (point - center);
}

vec2 mouseToComplex(vec2 point)
{
    return screenToComplex(point * resolution);
}

vec2 square(vec2 z)
{
    return vec2(z.x * z.x - z.y * z.y,
                2.0 * z.x * z.y);
}

bool line(vec2 a, vec2 b, vec2 p)
{
    vec2 ba = b - a;
    vec2 pa = p - a;
    
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    
    return length(pa - ba * h) < 0.005;
}

/*
float mandelbrot(vec2 z0, vec2 c)
{
    vec2 z = z0;

    for (int i = 0; i < maxIterations; ++i)
    {
        z = square(z) + c;
        
        if (length(z) > 2.0)
        {
            return float(i) / float(maxIterations);
        }
    }
    
    return 0.0;
}
*/

float smoothMandelbrot(vec2 z0, vec2 c)
{
    vec2 z = z0;
    
    float zLength = length(z);
    
    int n = 0;
    for (int i = 0; i < maxIterations; ++i)
    {
        if (zLength > maxLength) break;
        
        z = square(z) + c;
        
        zLength = length(z);
        
        ++n;
    }
    
    float value = float(n) - log(log(zLength) / logMaxLength) / logTwo;
    
    return clamp(value / float(maxIterations), 0.0, 1.0);
}

void main()
{
    width = resolution.x;
    height = resolution.y;
    zoom = complexWidth / width;
    center = vec2(width, height) / 2.0;

    vec2 pixel = screenToComplex(gl_FragCoord.xy);
    vec2 mousee = mouseToComplex(mouse);

    vec3 color = vec3(0.0);    

    float mandelbrot = smoothMandelbrot(zero, pixel);
    float julia = smoothMandelbrot(pixel, mousee);

    if (mandelbrot < 0.9) color += mandelbrot * mandelbrotColor;
    if (julia < 0.9) color += julia * juliaColor;

    vec2 current = zero;

    for (int i = 0; i < maxIterations; ++i)
    {
        vec2 previous = current;

        current = square(current) + mousee;

        if (line(previous, current, pixel))
        {
            color = lineColor;
        }
    }

    glFragColor = vec4(color, 1.0);
}

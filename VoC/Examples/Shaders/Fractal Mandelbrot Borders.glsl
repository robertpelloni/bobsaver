#version 420

// original https://www.shadertoy.com/view/wsfGDr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Created by Gabor Nagy (gabor.nagy@me.com)
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
//
// December 28, 2018
//
// Yet another shader to visualize the Mandelbrot set. I wanted to see what it would 
// look like if I rendered the borders, where the number of iterations required 
// increases.

#define AA 2
#define MAX_ITERATIONS 750

#define BACKGROUND_COLOR vec3(.95,.95,.95)
#define MANDELBROT_COLOR vec3(1., .5, 0.)
#define OUTLINE_COLOR vec3(0.,0.,1.)

// Calculates the iterations needed to escape the mandelbrot set.
int mandelbrot(vec2 uv)
{    
    vec2 c = uv;    
    vec2 z = vec2(.0, .0);
    
    for(int i=0; i<MAX_ITERATIONS; i++)
    {       
        z = vec2( (z.x*z.x)-(z.y*z.y), 2.0*z.x*z.y) + c;
        if(dot(z,z) > 4.0)
        {
            return i;
        }
    }
    return MAX_ITERATIONS;
}

// Maps from pixel coordinates to mandelbrot coordinates, and handles zooming.
vec2 calculateUV(vec2 p) {
    vec2 uv = (vec2(p.x, p.y) / resolution.xy) * 2. - 1.;
    uv.x *= resolution.x / resolution.y;
    
    // Zoom in and out as a function of time from -1. to 8.
    float zoom = 8. - (cos(time / 3.) * 4.5 + 4.5); 
    uv *= 1. / exp(zoom);

    // Zoom somewhere interesting.
    uv.x -= 0.98990;
    uv.y -= 0.30934;

    return uv;
}

// Calculates the pixel color at point p.
vec3 render(vec2 p) {

    vec3 color = BACKGROUND_COLOR;
    
    int iterations = mandelbrot(calculateUV(p));
    
    if (iterations == MAX_ITERATIONS) {
        // We're inside the mandelbrot set.
        color = MANDELBROT_COLOR;
    } else {
                
        // Calculate the iterations needed nearby.
        int left = mandelbrot(calculateUV(p+vec2(-.5,0.)));
        int top = mandelbrot(calculateUV(p+vec2(0.,-.5)));
        
        // Looks like abs() doesn't work for int on iOS.
        float iterationJump = max(abs(float(left - iterations)), 
                                  abs(float(top - iterations)));

        if (iterationJump > 0.) {
            // If the iteration change is greater than zero, we're on a border.
            color = OUTLINE_COLOR - vec3(min(.7, float(iterationJump) / 40.));
        }    
    }
    
    return color;
}

void main(void)
{
    vec3 color = vec3(0.0);
    
    for( int m=0; m<AA; m++ ) {
        for( int n=0; n<AA; n++ ) {
            vec2 p = gl_FragCoord.xy + (vec2(float(m),float(n)) / float(AA) - 0.5);
            color += render(p);
        }
    }
    
    color /= float(AA*AA);
    glFragColor = vec4(color, 1.0);
}

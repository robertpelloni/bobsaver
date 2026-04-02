#version 420

// original https://www.shadertoy.com/view/lsKfDV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define ITERS 128

#define USE_THIN_LINES 1

#define JULIA_OR_MANDELBROT 1 // set this to 1 to make a julia set, set it to 0 for mandelbrot

float ramp(in float minval, in float maxval, in float val) {
    return clamp((val - minval) / (maxval - minval), 0.0, 1.0);
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (2.0 * gl_FragCoord.xy - resolution.xy) / resolution.y;
    vec2 z = 1.0 * uv;
    
#if JULIA_OR_MANDELBROT
    vec2 mouse_norm = (2.0 * mouse*resolution.xy.xy - resolution.xy) / resolution.y;
    vec2 c = mouse_norm;
#else
    vec2 c = z;
#endif
    
    float min_dist = min(abs(z.x), abs(z.y));
    
    mat2 grad = mat2(1.0, 0.0, 0.0, 1.0);
    // so, in addition to wanting to compute iterations of the function f(z) = z^2+c, we
    // also want it's derivative, so we can estimate the distance in pixel space to the z
    // such that f^i(z) is zero in either the real or the complex axis.
    
    for (int i = 0; i < ITERS; ++i) {
             
        mat2 zprime = mat2(2.0 * z.x, 2.0 * z.y, -2.0 * z.y, 2.0 * z.x);
        // here's our derivative.
        // I could probably use some complex analysis shortcuts to simplify computation here
#if JULIA_OR_MANDELBROT
        grad = zprime * grad;
#else
        grad = zprime * grad + mat2(1.0, 0.0, 0.0, 1.0);
        // if we're computing the mandelbrot, we can't forget that c also depends on
        // our initial position.
#endif        
        // but I fully compute all four partial derivatives instead.

        vec2 grad_zx = grad[0];
        // here is the gradient of the real part with respect to the starting coordinate
        vec2 grad_zy = grad[1];
        // here is the gradient of the complex part with respect to the starting coordinate

        z = vec2(z.x * z.x - z.y * z.y, 2.0 * z.x * z.y) + c;
        // and here we actually perform our julia iteration, which is the tiniest part of the code
        
        float dist1 = abs(z.x) / length(grad_zx);
        // I wonder if I can get away with removing the sqrt calculation here somehow
        // Maybe Fabrice can chime in and help.
        // Or maybe I'll figure it out on my own.
        float dist2 = abs(z.y) / length(grad_zy);
        // see above comment.
        if (z.x * z.x + z.y * z.y > 10000.0) {
            break;
            // break out of the loop if we've diverged too far -- otherwise we get
            // numerical explosions, which look funny on some platforms
        }
        min_dist = min(min_dist, min(dist1, dist2));
    }
    

#if USE_THIN_LINES
    vec3 col = vec3(ramp(0.0 / resolution.y, 2.0 / resolution.y, min_dist));
#else
    vec3 col =
        vec3(ramp(0.0 / resolution.y, 2.0 / resolution.y, min_dist),
             ramp(1.0 / resolution.y, 3.0 / resolution.y, min_dist),
             ramp(2.0 / resolution.y, 4.0 / resolution.y, min_dist));
    // and here we compute our tricolored line
#endif
    // TODO : consider coloring by iteration

    // Output to screen
    glFragColor = vec4(col,1.0);
}

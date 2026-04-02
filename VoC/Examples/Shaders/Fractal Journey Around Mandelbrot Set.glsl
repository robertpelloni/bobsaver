#version 420

// original https://www.shadertoy.com/view/3dfBDN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// based on https://www.shadertoy.com/view/tsBcDc

#define ITER 256

const float OneSixth = 1.0 / 6.0;
const float zoomWidth = 0.05;
const vec4 boxCol = vec4(0.99, 0.99, 0.99, 1.0);

vec3 gradient(in float r) {    
    r /= 20.;
    r = pow(r, 0.2);
    vec3 rainbow = 0.5 + 0.5 * cos((5.5 * r + vec3(0.2, 0.45, 0.8)*6.));
    
    return rainbow;
}

vec2 uv2coord(vec2 uv) {
    vec2 coord = 4.0 * uv - 2.0;
    return vec2((mod(coord.x, 2.0) - 1.0) * resolution.x/resolution.y - 0.5, coord.y);
}

vec4 fractal(vec2 z, vec2 c) {
    for (int i = 0; i < ITER; ++i) {
        z = vec2(
            z.x*z.x - z.y*z.y + c.x,
            2.0 * z.x*z.y + c.y
        );

        float distSqr = dot(z, z);
        
        if (distSqr > 16.0)
            return vec4(gradient(float(i) + 1.0 - log2(log(distSqr) / 2.0)), 1.);
    }
    
    return vec4(0.0, 0.0, 0.0, 1.0);
}

vec2 centre(in float t) {
     //r = (1 - cos(theta))/2, x = r*cos(theta)+0.25, y = r*sin(theta)
//* the boundary of the period 2 disk: r = 0.25, x = r*cos(theta)-1, y = r*sin(theta)
    if (t < 1.) {
        return vec2(-2. + 0.75 * smoothstep(0., 1., t), 0.);
    } else if (t < 3.) {
        t = 3.141593 * smoothstep(1., 3., t);
        return vec2(-0.25 * cos(t) - 1., 0.25 * sin(t));
    } else if (t < 7.) {
         t = 3.141593 * smoothstep(3., 7., t);
        vec2 c = vec2(-cos(t), -sin(t));
        c *= (1. + cos(t)) / 2.;
        c.x += 0.2499;
        return c;
    } else {
        t = smoothstep(7., 10., t);
        return vec2(0.25 - 2.25 * t, sin(6.281 * t)/ (1. + 2. * t));   
        
    }
    
    
    
}

void main(void) {
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    float ar = resolution.y / resolution.x;
    vec2 coord = uv2coord(uv);
    
    //vec2 c = uv2coord(mouse*resolution.xy.xy/resolution.xy);
    float t = mod(time * 0.25, 10.);
    
    vec2 c = centre(t);
    
    vec2 box = vec2(0.17, 0.17);
    float boxWidth = 0.32;
    
    float boxDist = max(abs(uv.x - box.x), abs(uv.y - box.y))
        -boxWidth / 2.;
    
    if (boxDist < 0.0) {
       coord -= uv2coord(box);
       coord *= zoomWidth * 2.;
       coord += c;
        
       glFragColor = fractal(vec2(0.0, 0.0), coord);
       
       glFragColor = mix(
           boxCol,
           glFragColor,
           smoothstep(0., 0.005, abs(boxDist)));
       
        
    } else if (uv.x < 0.5) {
        // Mandelbrot
        coord += vec2(-0.3, -0.4);
        glFragColor = fractal(vec2(0.0, 0.0), coord);
        glFragColor = mix(
            boxCol,
            glFragColor,
            smoothstep(
                0., 
                0.015,
                abs(max(ar * abs(coord.x - c.x), abs(coord.y - c.y))-zoomWidth)
                )
        );
    }
    else {
        // Julia
        glFragColor = fractal(coord + vec2(0.5, 0.0), c);
    }
}

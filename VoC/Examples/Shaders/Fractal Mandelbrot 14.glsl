#version 420

// original https://www.shadertoy.com/view/7tS3RG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define B 256.0
#define N 200
#define PERIOD 10.0

float mandelbrot(vec2 c) {
   vec2 z = vec2(.0);
   float n = .0;
   for(int i = 0; i < N; ++i) {
     z = vec2( z.x*z.x - z.y*z.y, 2.0*z.x*z.y ) + c; // z = z^2 + c
     if( dot(z,z)>(B*B) ) break; // break if z is too high
     n += 1.0;
   }
   return (n == 200.0)? .0: n/float(N);
}

vec3 image(vec2 gl_FragCoord2) {
    vec2 uv = (gl_FragCoord2.xy / resolution.xy) * 2.0 - 1.0; // remap uv to [-1, 1]
    uv.x *= resolution.x / resolution.y;
        
    // calculate and apply zoom
    float zoom = .62 + .38*cos(time/PERIOD);
    zoom = pow(zoom, 7.0);
    vec2 c = vec2(-.745,.186) + uv*zoom;
    
    float f = mandelbrot(c)*2.0 - .5;
    
    // calculate color
    vec3 col = mix(vec3(.81,.06,.13), vec3(.80,.40,.0), f*f);

    return (f*f*(8.0 - 5.0*f))*col;
}

void main(void) {
    // anti-aliasing
    glFragColor = vec4(image(gl_FragCoord.xy + vec2(0,0)), 1.0f);
    glFragColor.rgb += image(gl_FragCoord.xy + vec2(.5,.0));
    glFragColor.rgb += image(gl_FragCoord.xy + vec2(.0,.5));
    glFragColor.rgb += image(gl_FragCoord.xy + vec2(.5,.5));
    glFragColor.rgb += image(gl_FragCoord.xy + vec2(.25,.25));
    glFragColor.rgb += image(gl_FragCoord.xy + vec2(.75,.25));
    glFragColor.rgb += image(gl_FragCoord.xy + vec2(.25,.75));
    glFragColor.rgb += image(gl_FragCoord.xy + vec2(.75,.75));
    glFragColor.rgb /= 8.0;
}

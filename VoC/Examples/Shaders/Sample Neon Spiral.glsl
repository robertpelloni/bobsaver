#version 420

// original https://www.shadertoy.com/view/llyyWD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159265359

void main(void) {
    vec2 R = resolution.xy,
         pos = (2.*gl_FragCoord.xy - R ) / min(R.x,R.y);
    vec3 color = vec3(0.0);
    
    float factor = 30.;
    float nb_spirals = 3.;
    
    float r = length(pos);
    float a = atan(pos.y, pos.x);

    float f = mod(a, 2. * PI / nb_spirals) / factor;
    
    float looped_time = fract(time / 4.);
    
    float thickness = 12./min(R.x,R.y);

    float spiral = smoothstep(thickness / 2., 0., abs(mod(r - f, 2. * PI / (nb_spirals * factor)) - thickness / 2.));
    
    float circle = smoothstep(0.8 + 0.02, 0.8, r);
    
    float green_loop_time = 1. / 4.;
    
    vec3 funky_color = vec3(cos(3. * a + looped_time * 2. * PI),
                            abs(mod(r - looped_time, green_loop_time) - green_loop_time / 2.) / green_loop_time,
                            1. - sin(2. * a + looped_time * 2. * PI));

    color = spiral * circle * funky_color;

    glFragColor = vec4(color, 1.0);
}

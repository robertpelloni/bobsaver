#version 420

// original https://www.shadertoy.com/view/wssBDS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float fractal(vec2 z, vec2 b) {
    float trap1 = 1e20;
    for(int i = 0; i < 1000; ++i) {
        z = vec2(z.x * z.x - z.y * z.y, 2. * z.x * z.y) + b;
        trap1 = min(trap1, dot(z, z));
    }
    return trap1;
}

void main(void)
{    
    vec3 col = vec3(0.);
    float aspect = 4. / 3.;
    vec2 uv = aspect * (2. * gl_FragCoord.xy - resolution.xy)/resolution.y;
    float t = time;
    float f = fractal(uv, vec2(sin(t)*.5 + .05, 
                               smoothstep(-2., 2., cos(t))));
    f = 1. + log(f*2.) / 4.;
    
    col += smoothstep(.5, -.5, vec3(f*f, f, f*f*f));    
    col += smoothstep(.25, -.25, vec3(f, f*f, f));

    
    //gamma correction
    col = pow(col, vec3(.4545));
    
    glFragColor = vec4(col,1.0);
}

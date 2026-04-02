#version 420

// original https://www.shadertoy.com/view/XlKBDG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv -= .5;
    uv.x *= resolution.x / resolution.y;
    
    vec3 col = vec3(.3, .3, 1.);
    
    vec2 center = vec2(0., 0.);
    float r = .1;
    float exc = .2;
    for (float i = 1.; i < 10.; ++i) {
        float theta = i * time+i;
        vec2 p = vec2( sin(theta) * exc, cos(theta) * exc) + center;
        col = mix(col, i*vec3(.05, .08, .1), smoothstep(.051, .03, length(uv - p) - r));
        r -= r * 0.5;
        exc -= r;
        center = p;
    }

    // Output to screen
    glFragColor = vec4(col,1.0);
}

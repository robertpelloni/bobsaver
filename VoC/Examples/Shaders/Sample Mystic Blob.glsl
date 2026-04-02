#version 420

// original https://www.shadertoy.com/view/XsKfDm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    const float tau = 3.14 * 2.;
    const float numRings = 10.;
    
    vec2 uv = (gl_FragCoord.xy - .5 * resolution.xy) / resolution.y;
    
    float len = length(uv);
    glFragColor.rgb = vec3(0., 0., 0.);
    
    for (float i = 0.; i < numRings; i++) {    
        float angle = atan(uv.y, uv.x) + 3.14 + i * (tau / numRings);
        float val = len + sin(angle * 6. + time) * .05 * sin((time + i * .5) * 2.);
        float size = .18 + .12 * sin(time + i * (tau / numRings));
        float lenVal = smoothstep(size, size + .1, val) * smoothstep(size + .06, size + .05, val);
        lenVal *= smoothstep(0., .3, len);
        float lerpVal = (i / (numRings * 1.5)) + ((sin(time) + 1.) / 4.);
        glFragColor.rgb += mix(vec3(1., 0., 0.2), vec3(0.25, 0., 1.), lerpVal) * lenVal;
    }
    glFragColor *= 1.25;
}

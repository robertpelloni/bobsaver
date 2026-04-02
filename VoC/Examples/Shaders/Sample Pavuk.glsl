#version 420

// original https://www.shadertoy.com/view/dlf3Dl

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float color(vec2 z) {
    float a = atan(z.x, z.y),
          d = 36.*pow(smoothstep(0., .8, dot(z, z)), .1),
          t = 7.*sin(a + time) + 5.*time + 2.*d,
          c = 2.6*sin(8.*a);
    vec2 w = z + c*c*z/(1.3*sin(t) - 1.6);
    return smoothstep(0., -.05, abs(dot(w, w)-.1)-.1);
}

void main(void) {
    vec2 R = resolution.xy;
    glFragColor = vec4(color(1.4*(gl_FragCoord.xy-.5*R)/R.y));
}

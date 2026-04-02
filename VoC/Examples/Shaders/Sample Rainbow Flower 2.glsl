#version 420

// original https://www.shadertoy.com/view/WttyRM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec2 uv = (gl_FragCoord.xy -.5*resolution.xy)/resolution.x;
    vec2 st = vec2(atan(uv.x, uv.y), length(uv));

    vec3 c = vec3(0);
    for (float i=1.; i<4.; i++) {
        uv = vec2(st.x/6.2814 + time*0.1*i, st.y * (1.-i/10.*sin(time)));
        float x = uv.x*(i+4.);
        float m = min(fract(x), fract(1.-x));
        c[int(i)-1] += smoothstep(0., 0.1, m*.3 +.1 - uv.y);
    }
    vec3 col = vec3(c);

    glFragColor = vec4(col,1.0);
}

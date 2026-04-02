#version 420

// original https://www.shadertoy.com/view/lt3yW7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float circle(vec2 p,float r) {
    return length(p) - r;
}

void main(void)
{
    vec2 uv = (2.*gl_FragCoord.xy - vec2(resolution.x, 0.)) / resolution.y;
    
    uv = abs(uv);
    for (float i = 0.; i < 4.; i++) {
        float a = i * 0.05;
        uv = mat2(cos(a), sin(a), -sin(a), cos(a)) * uv;
        uv = 1.5 * uv - smoothstep(0., 1., fract(time * 0.05) + 0.2)*1.8 + 0.6;
        uv = vec2(atan(uv.y, uv.x), -length(uv));
        uv.x += 1./uv.y * 1.5;
        uv.y = 1./pow(abs(uv.y), 1.2);
        uv = vec2(cos(uv.x), sin(uv.x)) * uv.y;
        uv = abs(uv);
    }
    
    float d = circle(uv - vec2(0.5, 0.4), 0.4);
    glFragColor = vec4(d);
}

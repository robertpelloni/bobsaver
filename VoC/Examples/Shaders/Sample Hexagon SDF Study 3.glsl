#version 420

// original https://www.shadertoy.com/view/wdVcDt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float hexSdf(vec2 p) {
        p.x *= 0.57735*2.0;
        p.y += mod(floor(p.x), 2.0)*0.5;
        p = abs((mod(p, 1.0) - 0.5));
        return abs(max(p.x*1.5 + p.y, p.y*2.0) - 1.0);
}

vec3 palette(float i) {
        return vec3(1.0, 1.0, 1.0);
}

void main(void) {
        float d = 1.0-hexSdf(gl_FragCoord.xy/100.0);
        glFragColor.rgb = vec3(d);
        glFragColor.a = 1.0;
}

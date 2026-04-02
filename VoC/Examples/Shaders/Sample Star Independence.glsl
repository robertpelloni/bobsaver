#version 420

// original https://www.shadertoy.com/view/DdXyzN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159265359

mat2 rot(float ang){
    float c = cos(ang);
    float s = sin(ang);
    return mat2(c, s, -s, c);
}

float sdStar(vec2 p, float radius, float rAng){
    p *= rot(rAng);
    float sAng = 2. * PI / 5.;
    float repeat = abs(mod(atan(p.x , -p.y), sAng) - .5 * sAng );
    return cos(sAng - repeat) * length(p) - radius * cos(sAng);
}

float rand(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

void main(void) {
    vec2 st = (gl_FragCoord.xy - 0.5 * resolution.xy) / resolution.y;
    
    vec2 uv = st * 4.;

    vec2 p = fract(uv) - 0.5;
    
    float d = sdStar(p, 0.4, cos(time * rand(floor(uv)) * 5.));
    
    glFragColor = vec4(vec3(.9, smoothstep(15. / resolution.y, 0., d) * .9, 0), 1);
}

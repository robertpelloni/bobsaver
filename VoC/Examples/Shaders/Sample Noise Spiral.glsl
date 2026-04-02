#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float rand(vec2 n) { 
    return fract(cos(dot(n, vec2(12.9898, 4.1414))) * 43758.5453);
}
float noise(vec2 n) {
    const vec2 d = vec2(0.0, 1.0);
    vec2 b = floor(n), f = smoothstep(vec2(0.0), vec2(1.0), fract(n));
    return mix(mix(rand(b), rand(b + d.yx), f.x), mix(rand(b + d.xy), rand(b + d.yy), f.x), f.y);
}
float fbm(vec2 n) {
    float total = 0.0, amplitude = 1.0;
    for (int i = 0; i < 4; i++) {
        total += noise(n) * amplitude;
        n += n;
        amplitude *= 0.5;
    }
    return total * 0.5;
}

void main() {
vec2  surfacePos = (gl_FragCoord.xy - resolution.xy*.5) / resolution.y;
    vec2 p = surfacePos*10.;
    vec3 c = vec3(0.);
    float a = atan(p.x,p.y);
    float r = length(p);
    float cc = fbm(p)+r+a*.5-time*1.;
    for (int i=1; i<=3; i++)
        cc = abs(sin(float(i)*1.*cc));
    c = vec3(cc+sin(r*2.+fbm(p*2.)*4.)*.5)*.5;
    glFragColor = vec4(c,1);
}

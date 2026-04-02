#version 420

// original https://www.shadertoy.com/view/wl2Sz1

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 hsv(in float h, in float s, in float v) {
    return mix(vec3(1.0), clamp((abs(fract(h + vec3(1, 2, 1) / 2.0) * 5.0 - 3.0) - 1.0), 0.0 , 1.0), s) * v;
}
void main(void)

 {
vec3 p = vec3 ((-1.0+gl_FragCoord.xy-0.5*resolution.xy), 0.0)/100.0;
    vec4 color = vec4(0);
    float m = 1.0;
    float t = time*0.1;
    vec2 c = vec2(sin(t), cos(t));

    float n = 18.5;
    const int iter = 2;
    for (int i = 0; i < iter; i++) {
        float l = length(p);
        m *= smoothstep(0.0, 1.0, l);
        p /= l*l*0.06;
        p.xy = vec2(tan(c.x*c.y)*p.x - cos(c.x)*p.y, sin(c.x)*p.y-cos(c.x)*p.x);
        p.xz = vec2(tan(c.x*c.y)*p.x - cos(c.y)*p.z, sin(c.y)*p.z-cos(c.y)*p.x);
        p = abs(mod((p), n)-n/2.0);
        
        color += vec4(hsv(l, 1.30, 1.0), 1.0);
    }

    glFragColor = vec4( color/float(iter) )*m;

}

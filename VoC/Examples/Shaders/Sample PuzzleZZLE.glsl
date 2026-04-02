#version 420

// original https://www.shadertoy.com/view/tddXD7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 hsv(in float h, in float s, in float v) {
    return mix(vec3(1.0), clamp((abs(fract(h + vec3(3, 2, 1) / 3.0) * 6.0 - 3.0) - 1.0), 0.0 , 1.0), s) * v;
}

void main(void) {
    vec3 p=vec3(gl_FragCoord.xy/1.67/resolution.y,.50)/1.;
    vec4 color = vec4(0);
    float m = 1.50;
    float t = time*0.1;
    vec2 c = vec2(sin(t), cos(t));
    float n = 18.5;
    const int iter = 2;
    for (int i = 0; i < iter; i++) {
        float l=max(abs(p.x-p.z), max(abs(p.y-p.z), abs(p.z-p.x)));
        m *= smoothstep(0.0, 1.0, l);
        p /= l*0.2;
        p.xy = vec2(atan(c.x*c.y)*p.x - acos(c.x)*p.y, asin(c.x)*p.y-acos(c.x)*p.x);
        p.xz = vec2(atan(c.x*c.y)*p.x - acos(c.y)*p.z, asin(c.y)*p.z-acos(c.y)*p.x);
        p = abs(mod((p), n)-n/2.0);
        color+=vec4(.5+.5*sin(time*7./8.+l), .5+.5*cos(time*11./8.+l), .5+.5*cos(time*13./8.+l),1.);    
        color *= vec4(hsv(l, l, l), 1.);
    }

    glFragColor = vec4( color/float(iter) )*m;

}

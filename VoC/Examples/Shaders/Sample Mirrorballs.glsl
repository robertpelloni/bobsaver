#version 420

// original https://www.shadertoy.com/view/tltXDj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    const float EPS = 0.001;
    const int MAX_STEPS = 200;
    vec2 uv = gl_FragCoord.xy/resolution.xy * 2. - 1.;
    uv.x *= resolution.x / resolution.y;
    vec3 ro = vec3(0,sin(time ) * 1.5, cos(time) * 2.);
    vec3 rd = normalize(vec3(uv, 1.5));
    vec3 col;
    vec3 p;
    float d, t = 0.;
    int i;
    for(i=0; i<MAX_STEPS; i++) {
        p = ro+rd*t;
        p.xz = mod(p.xz + 2., 4.) - 2.;
        float dSphere = length(p) - 1.25;
        if(dSphere < EPS) {
            t = EPS; // so this branch isn't triggered on the next iteration
            ro = p;
            rd = reflect(rd, normalize(p));
        }
        t += dSphere;
    }
    glFragColor = vec4((rd.y > 0. ? vec3(.5,.7,.9) : vec3(.9,.7,.5)) * (1.5 - abs(rd.y)), 1.);
}

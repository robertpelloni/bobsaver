#version 420

// original https://www.shadertoy.com/view/tlsGz2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float tr = 50.0;
#define P(t,tt) vec3(cos(ti+t) * tr, sin(ti) * 0.1, sin(ti+tt) * tr);
void main(void)
{
    vec2 p = (gl_FragCoord.xy * 2.0 - resolution.xy) / min(resolution.x, resolution.y);
    float ti = time * 2.;
    vec3 ro = P(0.,0.);
    vec3 ta = P(sin(ti), cos(ti));
    vec3 fo = normalize(ta-ro);
    vec3 ri = normalize(cross(vec3(cos(ti*0.5),sin(ti*0.5),0.), fo));
    vec3 up = normalize(cross(fo,ri));
    vec3 ray = mat3(ri,up,fo) * normalize(vec3(p, 1.5));
    
    float t = 0.0;
    vec3 col = vec3(0.);
    float a = 1.0;
    for(int i=0;i<300;i++) {
        vec3 pos = ro + ray * t;
        float d = -length(vec2(length(pos.xz) - tr, pos.y)) + 5.0;
        if (d < 0.001) {
            vec2 uv = vec2(atan(pos.z, pos.x), atan(pos.y, length(pos.xz) - tr)) / (acos(-1.)*2.) + 0.5;
            float c = smoothstep(0.05, 0.00, abs(fract(uv.y * 5.0) - 0.5));
            c = mix(c, 1.0, smoothstep(0.1, 0.00, abs(fract(uv.x * 10.0) - 0.5)));
            col += mix(vec3(c), mix(vec3(7., 4., 2.), vec3(2., 4., 7.), sin(ti) * 0.5 + 0.5), 1.0-exp(-t * 0.005)) * a;
            a *= 0.25;
            t = 0.002;
            ro = pos;
            ray = reflect(ray, normalize((normalize(vec3(pos.x, 0., pos.z)) * tr) - pos));
        }
        t += d;
    }
    glFragColor = vec4(col,1.0);
}

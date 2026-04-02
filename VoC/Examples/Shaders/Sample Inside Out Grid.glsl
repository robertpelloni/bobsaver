#version 420

// original https://www.shadertoy.com/view/4dtyRf

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

mat3 rot (vec3 s) {
        float     sa = sin(s.x),
                ca = cos(s.x),
                sb = sin(s.y),
                cb = cos(s.y),
                sc = sin(s.z),
                cc = cos(s.z);
        return mat3 (
            vec3(cb*cc, -cb*sc, sb),
            vec3(sa*sb*cc+ca*sc, -sa*sb*sc+ca*cc, -sa*cb),
            vec3(-ca*sb*cc+sa*sc, ca*sb*sc+sa*cc, ca*cb)
        );
    }
    mat3 mm;
    vec4 light;
    float map (vec3 p) {
        float a = 1.;
        float d = length(p-light.xyz)-light.w;
        d = min(d,max(15.-p.z,0.));
        p = mm*p;
        float r = dot(p,p);
        p = 4.*p/r;
        float b = .2/(r);
        p = (fract((p*0.5)/a)*2.-1.)*a;
        d = min(d,length(p.xz)-b);
        d = min(d,length(p.xy)-b);
        d = min(d,length(p.zy)-b);

          return d;
    }
    vec3 norm (vec3 p) {
        vec2 e = vec2 (.0001,0.);
        return normalize(vec3(
                map(p+e.xyy) - map(p-e.xyy),
                map(p+e.yxy) - map(p-e.yxy),
                map(p+e.yyx) - map(p-e.yyx)
            ));
    }
    vec3 dive (vec3 p, vec3 d) {
        for (int i = 0; i < 120; i++) {
            p += 0.55*d*map(p);
        }
        return p;
    }
void main(void) {
        float ui = float(frames);
        vec2 v = (gl_FragCoord.xy/resolution.xy)*2.-1.;
        v.x *= resolution.x/resolution.y;
        vec3 r = vec3(0,0,-10.);
        light = vec4(20.*sin(0.01*ui),2,-23,1);
        vec3 d = normalize(vec3(v,3.));
        mm = rot(0.01*ui*vec3(0,1,1));
        vec3 p = dive(r,d);
        d = normalize(light.xyz-p);
        vec3 bounce = dive(p+0.01*d,d);
        vec3 col = norm(p)*0.5+0.5;
        if (length(bounce-light.xyz) > light.w+0.1) col *= 0.2;
        if (length (p-r)>4e2) col *= 0.;
        glFragColor = vec4(col,1);
    }

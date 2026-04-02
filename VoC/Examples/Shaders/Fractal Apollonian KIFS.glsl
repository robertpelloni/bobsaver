#version 420

// original https://www.shadertoy.com/view/Xdcyzl

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

mat3 m;
float k;
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
vec3 app (vec3 v) {
    for (int i = 0; i < 70; i++) {
        v = abs(k*m*v/dot(v,v)*0.5-0.5)*2.-1.; 
    }return v;
}
vec3 ap (vec3 v) {
    for (int i = 0; i < 15; i++) {
        v = abs(k*m*v/dot(v,v)*0.5-0.5)*2.-1.; 
    }return v;
}
vec3 norm (vec3 p) {
        vec2 e = vec2 (.05,0.);
        vec3 g = ap(p);
        return normalize(vec3(
                ap(p+e.xyy).x - g.x,
                ap(p+e.yxy).y - g.y,
                ap(p+e.yyx).z - g.z
            ));
    }

void main(void)
{    
    vec2 uv = gl_FragCoord.xy/resolution.xy*2.-1.;
    uv.x *= resolution.x/resolution.y;

    float t = 0.05*time;
    m = rot(t+vec3(2,3,5));
    k = 1.3+0.1*sin(0.1*time);
    vec3 v = (.5+0.25*sin(0.3*time))*m*vec3(2.*uv,0);
    vec3 col = sin(app(v))*0.5+0.5;
    col = col*0.8+0.2*(sin(norm(v))*0.5+0.5);
    glFragColor = vec4(col,1.0);
}

#version 420

// original https://www.shadertoy.com/view/wlXXD4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAX_ITERS 10
#define MAX_MARCH 512
vec3 sq3 (vec3 v) {
    return vec3(
        v.x*v.x-v.y*v.y-v.z*v.z,
        2.*v.x*v.y,
        2.*v.x*v.z
    );
}
float squishy (float x) {
    return x*x*x;
}
float julia (vec3 p, vec3 c) {
    vec3 k = p;
    for(int i = 0; i<MAX_ITERS; i++) {
        k = sq3(k) + c;
        if(length(k)>2.) return 1.-squishy(float(i)/float(MAX_ITERS));
    }
    return -1.;
}
vec2 rotate2D (vec2 p, float angle){
    return vec2(p.x*cos(angle)-p.y*sin(angle), p.y*cos(angle)+p.x*sin(angle));\
}
float sdf (vec3 p) {
      vec3 r = p;
    r.xz = rotate2D(r.xz, time*0.3);
    return julia(p,
                 r
                 //vec3(sin(time*0.3)*0.7, cos(time*0.4)*0.7, p.z));
    );
    //return length(p)-1.;
}
vec4 trace (vec3 o, vec3 r) {
    vec3 p = o;
    float t = 0.;
    float s;
    int i;
    for(i = 0; i<MAX_MARCH; i++) {
        p = o+r*t;
        s = sdf(p);
        t+=s*0.01;
        if(s<0.001||t>10.) break;
    }
    return vec4(p, float(i));
}
const float E = 0.0001;
vec3 estimateNormal (vec3 p) {
    return normalize(vec3(
        sdf(vec3(p.x+E, p.y, p.z))-sdf(vec3(p.x-E, p.y, p.z)),
        sdf(vec3(p.x, p.y+E, p.z))-sdf(vec3(p.x, p.y-E, p.z)),
        sdf(vec3(p.x, p.y, p.z+E))-sdf(vec3(p.x, p.y, p.z-E))
    ));
}
void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv-=0.5;
    vec2 mouse = mouse*resolution.xy.xy/resolution.xy;
    mouse-=0.5;
    float aspect = resolution.y/resolution.x;
    uv.x/=aspect;
    mouse.x/=aspect;
    vec3 col = vec3(1.);
    vec3 cam = vec3(0., 0., -2.);
    vec3 ray = normalize(vec3(uv.xy*1.3, 1.));
    
    vec3 rot = vec3(mouse.y*5., -mouse.x*3., 0.);
    
    cam.xz = rotate2D(cam.xz, rot.y);
    ray.xz = rotate2D(ray.xz, rot.y);
    
    cam.zy = rotate2D(cam.zy, rot.x);
    ray.zy = rotate2D(ray.zy, rot.x);
    
    
    vec4 t = trace(cam, ray);
    vec3 end = t.xyz;
    vec3 light = vec3(0., 0., -5.);
    vec3 toLight = normalize(light-end);
    vec3 norm = estimateNormal(end);
    float diffuse = max(0.,dot(toLight, norm))*1.0;
    vec3 refl = reflect(ray, norm);
    float specular = pow(max(0.0, dot(refl, toLight)), 16.0)*1.0;
    float d = length(end-cam);
    float fog = 1.0 / (1.0 + d*d*0.5);
    col.gb -= t.w/float(MAX_MARCH);
    col *= (diffuse+specular) + 1.2;
    col *= fog;

    // Output to screen
    glFragColor = vec4(col,1.0);
}

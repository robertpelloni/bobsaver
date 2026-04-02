#version 420

// original https://www.shadertoy.com/view/3s3yDS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAX_STEPS 100
#define MAX_DIST 100.
#define SURF_DIST .0001
#define S smoothstep
#define T time
mat2 Rot(float a) {
    float s=sin(a), c=cos(a);
    return mat2(c, -s, s, c);
}
float Hash21(vec2 p) {
    p = fract(p*vec2(123.34,233.53));
    p += dot(p, p+23.234);
    return fract(p.x*p.y);
}
float sdBox2d(vec2 p, vec2 s) {
    p = abs(p)-s;
    return length(max(p, 0.))+min(max(p.x, p.y), 0.);
}
float GetDist(vec3 p) {
    float amount = 3.0;
    float r1 = 1.75, r2 = 0.3;
    vec2 cp = vec2(length(p.xz) - r1, p.y);
    float a = atan(p.x, p.z);
    cp *= Rot(a * round(amount) + time);
    cp.y = abs(cp.y) - 0.4;
    
    float d = length(cp) - r2;
       d = sdBox2d(cp, vec2(0.1, 0.3))-0.1;
    return d * 0.5;
}
float RayMarch(vec3 ro, vec3 rd) {
    float dO=0.;
    
    for(int i=0; i<MAX_STEPS; i++) {
        vec3 p = ro + rd*dO;
        float dS = GetDist(p);
        dO += dS;
        if(dO>MAX_DIST || abs(dS)<SURF_DIST) break;
    }
    
    return dO;
}
vec3 GetNormal(vec3 p) {
    float d = GetDist(p);
    vec2 e = vec2(.001, 0);
    
    vec3 n = d - vec3(
        GetDist(p-e.xyy),
        GetDist(p-e.yxy),
        GetDist(p-e.yyx));
    
    return normalize(n);
}
vec3 GetRayDir(vec2 uv, vec3 p, vec3 l, float z) {
    vec3 f = normalize(l-p),
        r = normalize(cross(vec3(0,1,0), f)),
        u = cross(f,r),
        c = f*z,
        i = c + uv.x*r + uv.y*u,
        d = normalize(i);
    return d;
}
vec3 Bg(vec3 rd) {
    float k = rd.y * 0.5 + 0.5;
    vec3 col = mix(vec3(0.5, 0.1, 0.1), vec3(0.2, 0.2, 0.6), k);
    return col;
}
void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    vec4 texColor = vec4(0.0);//texture(iChannel0, uv);
    vec2 m = vec2(1.0); //mouse*resolution.xy.xy/resolution.xy;
    vec3 col = vec3(0);
    vec3 ro = vec3(0, 3, -5);
    ro.yz *= Rot(-m.y*3.14+1.);
    ro.xz *= Rot(-m.x*6.2831);
    vec3 rd = GetRayDir(uv, ro, vec3(0), 1.);
    col += Bg(rd);
    float d = RayMarch(ro, rd);
    if(d<MAX_DIST) {
        vec3 p = ro + rd * d;
        vec3 n = GetNormal(p);
        vec3 r = reflect(rd, n);
        
        float spec = pow(max(0.0, r.y), 30.0);
        
        float dif = dot(n, normalize(vec3(1,2,3)))*.5+.5;
        col = mix(Bg(r), vec3(dif), 0.5)+spec;
        col += p / 7.5;
    }
    col = pow(col, vec3(.4545));
    glFragColor = vec4(col,1.0);
}

#version 420

// original https://www.shadertoy.com/view/dlSyWm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float PI = 3.141592653;
vec3 getRay(in vec3 cameraDir, in vec2 uv) { //get camear ray direction
    vec3 cameraPlaneU = vec3(normalize(vec2(cameraDir.y, -cameraDir.x)), 0);
    vec3 cameraPlaneV = cross(cameraPlaneU, cameraDir) ;
    return normalize(cameraDir*2.0 + uv.x * cameraPlaneU + uv.y * cameraPlaneV);
}
const float inf = 10000.;
vec2 sphere( in vec3 ro, in vec3 rd, float ra )
{
    float b = dot( ro, rd );
    float c = dot( ro, ro ) - ra*ra;
    float h = b*b - c;
    if( h<0.0 ) return vec2(inf); 
    h = sqrt( h );
    if (c < 0.0) return vec2(0, -b+h);
    return vec2(-b-h, -b+h);
}
bool inCone(in vec3 o, in float k) {
    return o.x*o.x+o.y*o.y+o.z*o.z*k < 0.0 && o.z < 0.0;
}
float cone(in vec3 o, in vec3 d, in float k) {
    o.z *= k;
    d.z *= k;
    float a = (d.x*d.x + d.y*d.y + k*d.z*d.z)*2.0;
    float b = 2.0*(o.x*d.x + o.y*d.y + k*o.z*d.z);
    float c = o.x*o.x + o.y*o.y + k*o.z*o.z;
    if (c < 0.0&&o.z>0.0) return 0.0;
    float disc = b*b - 2.*a*c;
    
    if (disc < 0.0) return inf;
    float dist = (-b - sqrt(disc))/a;
    if (dist < 0.0 || o.z+d.z*dist < 0.0) return inf;
    return dist;
}
float hit(in vec3 o, in vec3 d, in float kk, in float z, in float count, float an) {
    float g = 0.5*(count/PI);
    float f = 0.55;
    float dist = cone(o, d, -kk);
    if (dist >= inf) return inf;
    vec3 p = o+d*dist;
    if (p.z > 0.0) return inf;
    float angle = atan(p.x, p.y)+an;
    float fangle = floor(angle*g)/g;
    float tangle = abs(g*(angle-fangle)-0.5)*2.0;
    vec3 col;
    vec3 oo = o;
    o += d*dist;
    if (tangle < f) {
        fangle -= an;
        float k = (PI/count);
        float h = k*(1.-f);
        vec2 dir = vec2(cos(-fangle-k*2.0+h), sin(-fangle-k*2.0+h));
        float pz = -(dot(o.xy, dir))/dot(d.xy, dir);
        if (pz < 0.0) pz = inf;
        
        dir = vec2(cos(-fangle-h), sin(-fangle-h));
        float pzz = -(dot(o.xy, dir))/dot(d.xy, dir);
        if (pzz < 0.0) pzz = inf;
        float dd = (min(pz, pzz));
        vec3 cp = o+d*(dd);
        if (inCone(cp, -kk*kk*kk)) dist += dd;//return inf;
        else dist = inf;
        //dist += dd;
    }
    dist = min(dist, cone(oo, d, -kk*z));
    vec3 pos = oo+d*dist;
    return dist;
}
#define gear(ro, rd, size, teeth, time) d=min(d,hit(ro, rd, size, 0.8, teeth, time))
const float s2 = sqrt(2.);
const float s2i = 1./s2;
float hitShape(in vec3 ro, in vec3 rd) {
const float teeth = 12.;
    float m = 0.6;
    vec3 xo = vec3(ro.x,ro.y*s2i+ro.z*s2i,ro.z*s2i-ro.y*s2i);
    vec3 xd = vec3(rd.x,rd.y*s2i+rd.z*s2i,rd.z*s2i-rd.y*s2i);
    vec3 yo = vec3(ro.x*s2i+ro.z*s2i,ro.y,ro.z*s2i-ro.x*s2i);
    vec3 yd = vec3(rd.x*s2i+rd.z*s2i,rd.y,rd.z*s2i-rd.x*s2i);
    vec3 zo = vec3(ro.x*s2i+ro.y*s2i,ro.y*s2i-ro.x*s2i,ro.z);
    vec3 zd = vec3(rd.x*s2i+rd.y*s2i,rd.y*s2i-rd.x*s2i,rd.z);
    
    float d = inf;
    float g = (PI*2.0)/teeth*0.5;
    float time = time*0.5;
    
    gear(ro, rd, 0.6, teeth, time);
    gear(-ro, -rd, 0.6, teeth, -time);
    gear(-ro.yzx, -rd.yzx, 0.6, teeth, -time);
    gear(ro.yzx, rd.yzx, 0.6, teeth, time);
    gear(ro.zxy, rd.zxy, 0.6, teeth, time);
    gear(-ro.zxy, -rd.zxy, 0.6, teeth, -time);
    time += g;
    gear(-xo, -xd, 0.6, teeth, time);
    gear(xo, xd, 0.6, teeth, -time);
    gear(-xo.zxy, -xd.zxy, 0.6, teeth, time);
    gear(xo.zxy, xd.zxy, 0.6, teeth, -time);
    
    gear(-yo, -yd, 0.6, teeth, time);
    gear(yo, yd, 0.6, teeth, -time);
    gear(-yo.yzx, -yd.yzx, 0.6, teeth, time);
    gear(yo.yzx, yd.yzx, 0.6, teeth, -time);
    
    gear(-zo.yzx, -zd.yzx, 0.6, teeth, time);
    gear(zo.yzx, zd.yzx, 0.6, teeth, -time);
    gear(-zo.zxy, -zd.zxy, 0.6, teeth, time);
    gear(zo.zxy, zd.zxy, 0.6, teeth, -time);
    return d;
}
vec3 getColor(in vec3 ro, in vec3 rd) {
    vec2 bound = sphere(ro, rd, 1.0);
    vec2 innerBound = sphere(ro, rd, 0.8);
    if (bound.x >= inf) return vec3(0);
    float d = hitShape(ro+rd*bound.x, rd)+bound.x;
    
    float dis = d;
    if (dis >= bound.y) return vec3(0);
    if (dis >= innerBound.x) {
        d = hitShape(ro+rd*innerBound.y, rd)+innerBound.y;
        if (d > bound.y) return vec3(0);
    };
    vec3 p = ro+rd*d;
    return vec3(mix(vec3(0.6), vec3(1), 1.-1./(0.5+10.*(length(p)-0.8)))*exp(-d)*20.);
}
void main(void)
{
    vec2 uv = (gl_FragCoord.xy-resolution.xy*0.5)/resolution.y;
    vec2 m = vec2(time*0.5, 0.75*sin(time*0.5)+PI*0.5);
    //if (mouse*resolution.xy.z > 0.0) m = ((mouse*resolution.xy.xy)/resolution.xy) * vec2(6.28, 3.14159263);
        
    vec3 ro = vec3(sin(m.y) * cos(-m.x), sin(m.y) * sin(-m.x), cos(m.y))*4.25;
    vec3 rd = getRay(-normalize(ro), uv);
    vec3 color = getColor(ro, rd);

    glFragColor = vec4(color, 1);
}
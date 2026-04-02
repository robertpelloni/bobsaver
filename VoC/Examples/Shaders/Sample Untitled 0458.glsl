#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/wdc3RB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define AA 2
#define Unit 0.5*length(resolution.xy)

#define EPSILON 1e-5

struct Sphere{
    vec3 O;
    float r;
};
bool sphInt(in Sphere S, in vec3 P, in vec3 d, out float t, out vec3 n) {    // doesn't work when inside
    vec3 p = P - S.O; if (dot(p, d) >= 0.0) return false;
    vec3 k = cross(p, d); float rd2 = dot(k,k); if (rd2 >= S.r*S.r) return false;
    t = sqrt(dot(p,p) - rd2) - sqrt(S.r*S.r - rd2); if (t < EPSILON) return false;
    n = (p + t * d) / S.r; return true;
}
const Sphere sph1 = Sphere(vec3(-2.0,-2.0,1.0),1.0);
const Sphere sph2 = Sphere(vec3(3.0,-2.0,1.3),1.3);
const Sphere sph3 = Sphere(vec3(1.0,3.0,1.8),1.8);
const Sphere sph4 = Sphere(vec3(1.0,1.0,0.4),0.4);

vec3 traceRay(vec3 p, vec3 d, vec3 light){
    vec3 col=vec3(1.0), ecol;
    for (int i=0;i<64;i++){
        float t, mt=1e+12; vec3 n, mn; bool r=false;
        t=-p.z/d.z;
        if (t>EPSILON){
            mt=t, mn=vec3(0.0,0.0,1.0), r=true;
            vec3 q=p+t*d;
            ecol = ((int(floor(q.x))&1)==(int(floor(q.y))&1)) ? vec3(135,206,250)/256.0 : vec3(148,166,188)/256.0;
        }
        if (sphInt(sph1,p,d,t,n) && t<mt) r=true, mt=t, mn=n, ecol=vec3(221,160,221)/256.0;
        if (sphInt(sph2,p,d,t,n) && t<mt) r=true, mt=t, mn=n, ecol=vec3(173,216,230)/256.0;
        if (sphInt(sph3,p,d,t,n) && t<mt) r=true, mt=t, mn=n, ecol=vec3(255,182,193)/256.0;
        if (sphInt(sph4,p,d,t,n) && t<mt) r=true, mt=t, mn=n, ecol=vec3(244,164,96)/256.0;
        if (r) {
            p+=mt*d;
            d-=2.0*dot(mn,d)*mn;
            col*=ecol;
        }
        else {
            col *= vec3(max(dot(d,light),0.0));
            break;
        }
    }
    return col;
}

void main(void)
{
    float h = 2.0*(cos(0.4*time)+2.0);
    float r = sqrt(40.0-h*h) + 0.5*(cos(time)+1.0) + 3.0;
    vec3 pos = 2.0*vec3(r*cos(time), r*sin(time), h);
    vec3 dir = vec3(0.0,0.0,1.0)-pos;
    
    float rz=atan(dir.x,-dir.y), rx=atan(length(dir.xy),dir.z);
    mat3 M=mat3(cos(rz),sin(rz),0,-sin(rz),cos(rz),0,0,0,1)*mat3(1,0,0,0,cos(rx),sin(rx),0,-sin(rx),cos(rx));
    
    vec3 light = normalize(vec3(0.0,0.0,1.0));
    
    vec3 col = vec3(0.0,0.0,0.0);
    for (int i=0;i<AA;i++) for (int j=0;j<AA;j++) {
        vec3 d = M*vec3(0.5*resolution.x-(gl_FragCoord.x+float(i)/float(AA)),-0.5*resolution.y+(gl_FragCoord.y+float(j)/float(AA)),Unit);
        col += traceRay(pos,normalize(d),light);
    }
    col/=float(AA*AA);

    glFragColor = vec4(col,1.0);
}

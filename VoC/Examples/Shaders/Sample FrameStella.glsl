#version 420

// original https://www.shadertoy.com/view/3llBzN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define rot(a) mat2(cos(a), sin(a), -sin(a), cos(a))

float deFrameStella(vec3 p){
    p = abs(p)-1.;
    if (p.x < p.z) p.xz = p.zx;
    if (p.y < p.z) p.yz = p.zy;
    if (p.x < p.y) p.xy = p.yx;
    return length(cross(p,normalize(vec3(0,1,1))))-0.1;
}

float map(vec3 p){
    return deFrameStella(p);
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy*2.-resolution.xy)/resolution.y;
    vec3 p,
    ro=vec3(0,0,-4),
    rd=normalize(vec3(uv,2));
    float h=0.,d,i,zoom = 1.5;
    ro*=zoom;
    for(i=1.;i<50.;i++){
        p=ro+rd*h;
        p/=zoom;
        p.xy*=rot(time*.6);
        p.yz*=rot(time);
        d=map(p);
        if(d<0.001)break;
        h+=d;
    }
    glFragColor.xyz+=10./i;  
}

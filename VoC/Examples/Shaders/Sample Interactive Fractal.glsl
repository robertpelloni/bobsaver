#version 420

// original https://www.shadertoy.com/view/dtSSDV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Fork of "Fork Fractal 77 sleeplessm 565" by sleeplessmonk. https://shadertoy.com/view/mt2XDy
// 2023-02-17 01:27:35

#define R(p,a,r)mix(a*dot(p,a),p,cos(r))+sin(r)*cross(p,a)
#define H(h)(cos((h)*6.3+vec3(0,23,21))*.5+.5)
void main(void)
{
    vec2 mouse = (mouse*resolution.xy.xy == vec2(0.)) ? vec2(1.0) : mouse*resolution.xy.xy/resolution.xy;
    mouse.x += 0.5;
    if(mouse==vec2(1.0)) mouse=vec2(sin(fract(time/0.234234)*3.14),cos(fract(time/0.63234234)*6.39));
      
    glFragColor=vec4(0);
    vec3 p,r=vec3(resolution.xy,1.0),
    d=normalize(vec3((gl_FragCoord.xy-.65*r.xy)/r.y,0.5));
    float g=0.,e,s;
    for(float i=0.;i<19.;i++) {
        p=g*d;
        p.z-=.6;
        p=R(p,normalize(vec3(1.*mouse.x,2.,3.*mouse.y)),time*.6);
        s=1.42;//1.;//4.;
        for(int j=0;j<6;j++) {
            p=abs(p);
            //p=p.x<p.y?p.zxy:p.zyx;
            s*=e=(1.8/min(dot(p,p),1.3))*mouse.x/mouse.y;
            p=p*e-vec3(15,3,2);
        }
        g+=e=length(p.xz)/s;
        glFragColor.rgb+=mix(r/r,H(log(s)),.7)*.08*exp(-i*i*e);
    }
    glFragColor=pow(glFragColor,vec4(3));
 }

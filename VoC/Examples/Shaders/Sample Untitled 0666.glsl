#version 420

// original https://www.shadertoy.com/view/NlcSDS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// reference
// https://shadertoy.com/view/stcSDM
// https://www.shadertoy.com/view/fdfSDH

#define R(p,a,r)mix(a*dot(p,a),p,cos(r))+sin(r)*cross(p,a)
#define H(h)(cos((h)*6.3+vec3(0,23,21))*.5+.5)
void main(void)
{
    vec4 O=vec4(0);
    vec3 p,r=vec3(resolution.xy,1.0),d=normalize(vec3((gl_FragCoord.xy-.5*r.xy)/r.y,1.));
    for(float i=0.,g=0.,e,f,t=time;++i<99.;){
        p=g*d;
        p.z-=4.;
        p=R(p,vec3(.577),t);
        f=length(p);
        vec4 q= vec4((e=2./(1.+dot(p,p)))*p,--e);
        q.yzw=R(q.yzw,vec3(1,0,0),t);
        //p=1./(1.+q.w)*q.xyz;
        p=q.xyz/++q.w; // thanks Xor
        for(int j=0;j++<2;)p=abs(p),p=p.x<p.y?p.zxy:p.zyx;
        g+=e=(length(p.xz-1.)-.2)*.5*       // sdf
            min(1.,1./length(p))*max(1.,f); // Numerical correction
        O.xyz+=mix(vec3(1),H(atan(p.y,p.x)*.6+.2*t),.5)*.01*exp(-i*i*e);
    }
    O*=O;
	glFragColor=O;
}

#version 420

// original https://www.shadertoy.com/view/7stcz2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define R(p,a,t) mix(a*dot(p,a),p,cos(t))+sin(t)*cross(p,a)
#define H(h) (cos((h)*6.3+vec3(0,23,21))*.5+.5)

void main(void)
{
    vec4 O=vec4(0);
    vec3 p,r=vec3(resolution.xy,1.0),
    d=normalize(vec3((gl_FragCoord.xy-.5*r.xy)/r.y,1));
    float i=0.,g=0.,e,s;
    for(;i++<90.;){
        p=d*g;
        p.z-=1.5;
        p=R(p,vec3(.577),time*.4);
        p-=i/2e4; //https://twitter.com/zozuar/status/1527091919511248897
        e=s=2.;
        for(int i=0;i++<6;)
            p=abs(p)-.2,
            p=p.x<p.y?p.zxy:p.zyx,
            e=min(e,(length(vec2(length(p.xy)-.4,p.z))-.1)/s),
            s*=1.8,
            p*=1.8;
        g+=e;
        O+=.015/exp(i*i*e);
    }
    O.rgb*=mix(vec3(1),H(p.x*.3),.6);
    O*=O*O;    
	glFragColor = O; 
}

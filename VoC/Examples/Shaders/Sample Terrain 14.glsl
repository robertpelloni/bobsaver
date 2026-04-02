#version 420

// original https://www.shadertoy.com/view/ftd3DX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define R(a)mat2(cos(a),sin(a),-sin(a),cos(a))
#define r resolution.xy
#define t time

void main(void)
{
    vec4 o=vec4(0);
    for(float i,e,g,s;i++<50.;g+=e*.5){
        vec3 c=vec3(4.4,5,5.6),n,p=vec3((gl_FragCoord.xy-.5*r)/r.y*g,g);
        p.zy*=R(.4+sin(t/3.)*.2);
        s=1.4;
        p.z+=t;
        for(e=++p.y;s<1e3;s*=1.7)
            p.xz*=R(s),
            n.xz*=R(s),
            n+=cos(p*s),
            e+=sin(p.x*s)/s/2.;
        n.y=.2;
        n/=length(n);
        e-=n.y;
        c.x+=n.y*3.;
        o.rgb+=mix(exp(n.z-c),c/3e2,min(g/9.+e,1.4));
    }
	glFragColor=o;
}

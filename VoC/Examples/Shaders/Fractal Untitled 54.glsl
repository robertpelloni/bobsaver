#version 420

// original https://www.shadertoy.com/view/sdB3DD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define R(p,a,r)mix(a*dot(p,a),p,cos(r))+sin(r)*cross(p,a)
#define hue(h)(cos((h)*6.3+vec3(0,23,21))*.5+.5)
#define hash(x)fract(sin(x*5555.5))

void main(void)
{
    vec4 O=vec4(0);
    vec3 p,r=vec3(resolution,1.0),
    d=normalize(vec3((gl_FragCoord.xy-.5*r.xy)/r.y,1.5));  
    for(float i=0.,j,g=0.,e,m,n;i++<100.;){
        vec3 p=d*g;
        p=R(p,normalize(vec3(1,2,3)),.5);
        p-=vec3(-.3,.2,-time*.3);
        n=hash(floor(p.z)+234.5);
        p.z=fract(p.z)-.5;     
        m=.1;
        vec2 z=p.xy;
        for(j=0.;
            length(vec2(dot(z,z),p.z))<4.&&j++<100.;
            m=min(m,length(vec2(dot(z,z),p.z)))
        )
            z=mat2(z,-z.y,z.x)*z-vec2(.8,.18)+n*.05;
        g+=e=.5*m;
        e<.01?O.xyz+=mix(vec3(1),hue(log(j)*.6+n),.7)*.3*exp(-5e-4*i*i):p;
  }
  glFragColor=O;
}

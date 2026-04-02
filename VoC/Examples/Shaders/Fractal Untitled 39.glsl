#version 420

// original https://www.shadertoy.com/view/wtKBRd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define R(p,a,r)mix(a*dot(p,a),p,cos(r))+sin(r)*cross(p,a)
#define H(h)(cos((h)*6.3+vec3(0,23,21))*.5+.5)
void main(void)
{
    vec4 O=vec4(0);
    vec3 p,r=vec3(resolution.xy,1.0),
    d=normalize(vec3((gl_FragCoord.xy-.5*r.xy)/r.y,1));  
    for(float i=1.,g=0.,e,s;
        ++i<99.;
        O.rgb+=mix(vec3(1),H(log(s)/5.),.5)*pow(cos(i*i/64.),2.)/e/2e4
    )
    {
        p=g*d-vec3(0,-.25,1.3);
        p=R(p,normalize(vec3(1,8,0)),time*.1);
        s=3.;
        for(int i=0;
            i++<4;
            p=vec3(2,4,2)-abs(abs(p)*e-vec3(3,5,1))
        )
            s*=e=1./clamp(dot(p,p),.1,.6);
        g+=e=min(length(p.xz)-.02,abs(p.y))/s+.001;
     }
    glFragColor=O;
}

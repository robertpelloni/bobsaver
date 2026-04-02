#version 420

// original https://www.shadertoy.com/view/WlGyWK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define R(a) mat2(cos(a),sin(a),-sin(a),cos(a))
void main(void)
{
    vec4 O = glFragColor;
    O-=O;
    for(float g,e,i=0.;++i<80.;e<1e-4?O+=.9/i:O)
    {
        vec3 r=vec3(resolution,0.0),
        p=g*vec3((gl_FragCoord.xy-.5*r.xy)/r.y,1);
        p.y+=3.;
        p.xz*=R(time*.2);
        for(int j=0;++j<8;)
            p.z-=.3,
            p.xz=abs(p.xz),
            p.xz=(p.z>p.x)?p.zx:p.xz,
            p.xy=(p.y>p.x)?p.yx:p.xy,
            p.z=1.-abs(p.z-1.),
            p=p*3.-vec3(10,4,2);
        g+=e=length(p)/6e3-.001;
    }
    glFragColor = O;
}

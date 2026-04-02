#version 420

// original https://www.shadertoy.com/view/sdtXzs

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

mat2 R(float a){
    return mat2(cos(a), sin(a), -sin(a), cos(a));
}

void main(void)
{
    vec2 FC=gl_FragCoord.xy;
    vec4 C=glFragColor;

    float o,i,e,f,s, g=4., t=time, k=.1;
    vec3 p,q, r=vec3(resolution.xy,1.0), l=vec3(2.);
    
    for(;i++<1e2;g+=min(f,max(e,.4))*k){
        s=2.;
        p=vec3((FC.xy-r.xy/s)/r.y*g,g-5.);
        k*=1.015;
        p.yz*=R(-.7);
        p.z+=t;
        for(e=f=p.y;s<4e2;s/=.6)
            p.xz*=R(s),
            q=p,
            q.x+=t*.5,
            e+=abs(dot(sin(q.xz*s*.1)/s,l.xz*2.)),
            f+=abs(dot(sin(p*s*.15)/s,l));
         o=1.+(f>1e-3?(e>.01?f*e:-exp(-e*e)):-1.);
         
         C *= .96;
         C.rgb += .1*max(o,.5)*(exp(-f)*vec3(.5,.3,.2)/4.+exp(-e)*vec3(.2,.1,.0));
         }
    
    glFragColor=C;
}

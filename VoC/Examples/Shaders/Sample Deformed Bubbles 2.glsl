#version 420

// original https://www.shadertoy.com/view/7l2fzc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void) {
    float t=time;
    vec2 r=resolution.xy,
    uv=(gl_FragCoord.xy*2.-r)/min(r.x,r.y);
    vec3 ro=vec3(0.,0.3,t),c,f,dir=normalize(vec3(uv,1.)),p;
    vec3 l1=ro+vec3(3.,2.,-4.),
    l2=ro+vec3(-2.,-1.,-3.),
    l3=ro+vec3(3.,-1.,-4.);
    ro+=5.*(vec3(mix(vec2(0.49,0.57), 0.5*resolution.xy.rg/r, step(0.1, mouse*resolution.xy)),-0.4)*2.-1.);
    float d=.5,e=1.,i,j,s,ss;
  
    for(;i++<99.&&e>.001;j=0.){
        p=ro+dir*d;
        p.z+=p.x*.1;
        p.x+=sin((p.z+p.y*.4))*.3;
        p.y+=cos((p.z+p.x*.3))*.4;
        vec3 
        n=l1-p;c+=vec3(.5,1.,2.)/(1.+dot(n,n));
        n=l2-p;c+=vec3(1.5,.5,.5)/(1.+dot(n,n));
        n=l3-p;c+=vec3(.5,1.,.5)/(1.+dot(n,n));
        ss=2.;
        for(;j++<9.;) {
            p=mod(p,2.)-1.;
            s=1./max(.1, dot(p,p));
            ss*=s;
            p=p.zxy;
            p*=s;
        }
        e=length(p)/ss-.02;
        e*=.5;
        d+=e*.5;
    }
    c*=.1;
    glFragColor = vec4(c/(1.+c),1.);
}

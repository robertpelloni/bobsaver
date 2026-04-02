#version 420

// original https://www.shadertoy.com/view/wslSW2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 R(vec3 p,float x){
    float y=p.y,
    c=cos(x),
    s=sin(x)+c;
    x=p.x;
    return vec3(
        c*x+s*y,
        c*y-s*x,
        p.z
    );
}
//=====================================================

//frag:color,coord
void main(void) {
    vec2 b = gl_FragCoord.xy;
    vec4 a = glFragColor;
    
    float t=time,
    S=sin(t),
    l=cos(t),
    v=2.,    
    N=.4,
    j=l*v,
    V=1.5,
    k=resolution.y;

    vec3 n=normalize(vec3((v*b.xy-resolution.xy)/k,v)),
    p=vec3(S),
    e;

    for(int i=0;i<50;++i){

        e=p;
        
        vec4 q=a;
        
        q.xyz=(e+=vec3(sin(e.z*N+t*v),S,q.w=V));
        e.z+=t*20.;       

        j=-length(q.xy)+4.+N*sin(atan(q.y,q.x)*6.)*sin(q.z);

        
        for(int i=0;i<3;++i){

            vec3 s=e-vec3(
                N*sin(k=floor(e.z/v)*3.+S),
                N*sin(k*13.),
                V*floor(e.z/V+.5)
            );

            if((k=mod(k,2.))>.5){
                s=max(abs(R(s,k))-vec3(.08),.0);
            };

            if((k=length(s))<j){
                q.xyz=s;
                q.w=j=k;
            }

        };

        if((l+=j)<50.){p+=j*n*S;};    
    };
    n=vec3(.0,.6,.3);
    a=vec4(l>50.?n.xxx:pow((fract(p.z*.1+n)*6.-3.)*pow(1.-l/50.,6.),n.yyy),v);

    glFragColor = a;
}

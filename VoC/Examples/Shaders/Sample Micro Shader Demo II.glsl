#version 420

// original https://www.shadertoy.com/view/fdySWh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define R resolution
#define T time
#define rot(a) mat2(cos(a),sin(a),-sin(a),cos(a))
void main(void) {
    vec2 F=gl_FragCoord.xy;
    float i=0.,k=.3,d=0.,e=5.,f=0.,t=T*.5,
          id=0.,f5=.57735027,f7=.78539816;
    for(;++i<1e3;){                                      
        vec3 p=d*vec3((F.xy-.5*R.xy)/R.y,1);             // position;
        p.y+=T;
        p =vec3(mod(p.xy+3.,6.)-3.,p.z+T);               // move and rep
        id = floor((p.z+1.)/2.); 
        p.xy*=rot(id*6.-t);                              // rotate column - try 4. or 3.
        p.xz=vec2(abs(p.x)-2.,mod(p.z+1.,2.)-1.);        
        mat2 rn = rot(id+t);                             // rotate object
        p.yz*=rn;p.xz*=rn;
        vec3 r=abs(p);                                   // make shape
        e = (r.x+r.y+r.z-.6)*f5;
        p.xz*=rot(f7); r=abs(p);
        e = min((r.x+r.y+r.z-.6)*f5,e);       
        e = max(abs(e),1e-5);                            // distance using max
        d += abs(e*.0965);                               // to make transparent
                          
    }
    glFragColor =vec4(1.-(d*vec3(.045,.025,.015)),1.);             // output
}

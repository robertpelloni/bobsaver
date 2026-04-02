#version 420

// original https://www.shadertoy.com/view/sl3Szf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define r(a) mat2(cos(a),sin(a),-sin(a),cos(a))
#define T (time+step(40.,time)*11.)

void main(void) { 
    vec3 R = vec3(resolution.xy,1.0),                          //Setup camera
         ro = vec3(0,0,-2),                        //
         rd = normalize(vec3((2.*gl_FragCoord.xy-R.xy)/R.x,.8)); //
    ro.zx *= r(T*.1);                              //
    rd.zx *= r(T*.1);                              //
    float t=.0,f=1.,i=f,h=f;     //Setup variables
    vec3 c = vec3(0), p=c;       //
    mat2 r1 = r(.1+T*.03);       //
    while (t<3.) {               //
        p = ro+rd*t;             //
        for (int i=0;i<20;i++) { //
            p = abs(p.yzx)*1.1-vec3(.044,0,.22+T*.009); //Iterate point
            p.yz *= r1;                                 //
        }
        h = length(p-vec3(clamp(p.xy,-.2,.8),0.))*.14; //Find and step by distance
        i = max(h,.002)*f;                             //
        t += i;                                        //
        c += exp(2.-t*3.) * (cos(p.x*6.+vec3(9,4,5.3))*.5+.5) * max(0.,f-4e2*h) * i*12.; //fog, colour, threshold, weight
        f*=1.005; //Accelerate ray
    }
    
    glFragColor = sqrt(c).rgbb; //Cheap gamma
}

#version 420

//original https://www.shadertoy.com/view/ld2GRG

uniform float time;
uniform vec2 resolution;
uniform sampler2D backbuffer;

out vec4 glFragColor;

//orbit traps from julia version of fractal formula z=(z+1/z+c)*-scale;

#define iterations 60
#define scale -.3
#define julia vec2(1.8,.26)

#define orbittraps vec3(.155,.144,0.015)
#define trapswidths vec3(.01,.03,.3)

#define trap1color vec3(255.,60.,10.)/256.
#define trap2color vec3(50.,100.,255.)/256.
#define trap3color vec3(1.,.9,.75)

#define trapsbright vec3(2.2,1.7,1.)
#define trapscontrast vec3(.25,2.,5.)

#define saturation .35
#define brightness .9
#define contrast 4.
#define minbright .75

#define antialias 3.

void main(void)
{
    vec3 aacolor=vec3(0.);
    vec2 uv=gl_FragCoord.xy / resolution.xy - 0.5;
    uv.x*=resolution.x/resolution.y;
    vec2 pos=uv.xy;
    float t=time*.04;
    float zoo=.11-sin(t*2.)*.05;
    pos*=zoo; 
    float a=radians(25.+sin(t*8.)*5.);
    pos*=mat2(cos(a),sin(a),-sin(a),cos(a));
    pos+=vec2(.75,.1)+vec2(-sin(t*2.)*2.,-cos(t)*.3)*.1;
    vec2 pixsize=2./resolution.xy*zoo;
    float av=0.;
    vec3 its=vec3(0.);
    for (float aa=0.; aa<9.; aa++) {
        vec3 otrap=vec3(1000.);
        if (aa<antialias*antialias) {
            vec2 aacoord=floor(vec2(aa/antialias,mod(aa,antialias)));
            vec2 z=pos+aacoord*pixsize/antialias;
            for (int i=0; i<iterations; i++) {
                vec2 cz=vec2(z.x,-z.y);
                z=z+cz/dot(z,z)+julia;
                z=z*scale;
                float l=length(z);
                vec3 ot=abs(vec3(l)-orbittraps);
                if (ot.x<otrap.x) {
                    otrap.x=ot.x;
                    its.x=float(iterations-i);    
                }
                if (ot.y<otrap.y) {
                    otrap.y=ot.y;
                    its.y=float(iterations-i);    
                }
                if (ot.z<otrap.z) {
                    otrap.z=ot.z;
                    its.z=float(iterations-i);    
                }
            }
        }
        otrap=pow(max(vec3(0.0),trapswidths-otrap)/trapswidths,trapscontrast);
        its=pow(its/float(iterations),vec3(.2));
        vec3 otcol1=otrap.x*pow(trap1color,3.5-vec3(its.x*3.))*max(minbright,its.x)*trapsbright.x;
        vec3 otcol2=otrap.y*pow(trap2color,3.5-vec3(its.y*3.))*max(minbright,its.y)*trapsbright.y;
        vec3 otcol3=otrap.z*pow(trap3color,3.5-vec3(its.z*3.))*max(minbright,its.z)*trapsbright.z;
        aacolor+=(otcol1+otcol2+otcol3)/3.;
    }
    aacolor=aacolor/(antialias*antialias);
    vec3 color=mix(vec3(length(aacolor)),aacolor,saturation)*brightness;
    color=pow(abs(color),vec3(contrast))+vec3(.05,.05,.08);        
    glFragColor = vec4(color,1.0);
}

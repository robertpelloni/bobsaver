#version 420

// original https://www.shadertoy.com/view/sdBBWV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// loop trick from https://twitter.com/zozuar/status/1483236063342698503

#define hsv(h,s,v) mix(vec3(1),clamp((abs(fract((h)+vec3(3,2,1)/3.)*6.-3.)-1.),0.,1.),(s))*(v)
#define r resolution.xy
#define t time

void main(void) //WARNING - variables void ( out vec4 O, in vec2 C ) need changing to glFragColor and gl_FragCoord.xy
{
    vec4 O=vec4(0);
	vec4 p=vec4(0);
    float e,s=1.,g,j=0.;
    for(int i=0;i<490;)
        p=i++%7<1?
            g+=e=length(p.yz)/s,
            O.rgb+=hsv(log(s)*.3,.5,.02/exp(.1*j*j*e)),
            j++,
            s=1.,
            asin(cos(vec4((gl_FragCoord.xy-r*.5)/r.y*g,g+t,.3)))
        :
            (
            s*=e=2./min(dot(p,p),2.),
            p=.05-abs(p-.05),
            abs(p.x<p.y?p.wzxy:p.wzyx)*e-vec4(.8,.5,.4,1)
            )
        ;
    O*=O;
	glFragColor=O;

}

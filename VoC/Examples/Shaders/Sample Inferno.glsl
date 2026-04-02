#version 420

// original https://www.shadertoy.com/view/msKfRR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec2 I = gl_FragCoord.xy;
    vec4 O = vec4(0.0);
    
    O*=0.;
    vec3 p, q, r = vec3(resolution.xy,1.0);
    
    for(float i=1.,z; i>0.; i-=.02)
        z=p.z = sqrt(max(z= i - dot( p = vec3(I+I-r.xy,0)/r.y, p ) , -z/1e4)),
        p.xz *= mat2(cos(time*.2+vec4(0,11,33,0))),
        O += sqrt(z)
             * pow( cos( dot( cos(q+=p/2.),sin(q.yzx)) /.3) *.5 +.5, 8.)
             * ( i* sin( i*20.+vec4(6,5,4,3)) + i ) / 7.;
    O*=O;
    
    glFragColor = O;
}
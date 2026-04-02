#version 420

// original https://www.shadertoy.com/view/tldfzn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define R(p,a,r)mix(a*dot(p,a),p,cos(r))+sin(r)*cross(p,a)
#define H(t) (cos((vec3(0,2,-2)/3.+t)*6.24)*.5+.5)
void main(void) //WARNING - variables void ( out vec4 O, vec2 C) need changing to glFragColor and gl_FragCoord.xy
{
    for(float g,d,e,i=0.;
        ++i<99.;
        g+=e*.5
        )
    {
        vec3 r=vec3(resolution,0.0),
        p=R(vec3(g*(gl_FragCoord.xy-.5*r.xy)/r.y,g+time*1.),
            vec3(.577),
            time*.02
            );
        p.xz=mod(p.xz,6.)-3.;
        e=max(
            .02,
            abs(length(p.xz)-2.)+
            (
                (abs(
                    dot(
                        vec2(atan(p.x,p.z)/3.14,mod(p.y+time,4.)-2.),
                        vec2(.7)
                    )
                )>.7
            )?.2:0.));
        glFragColor.xyz+=mix(vec3(1),H(g*.1),.8)*exp(-e*9.)*.03;
    }
}

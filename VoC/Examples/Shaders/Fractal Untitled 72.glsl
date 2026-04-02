#version 420

// original https://www.shadertoy.com/view/Nsy3Dy

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define R(p,a,r)mix(a*dot(p,a),p,cos(r))+sin(r)*cross(p,a)
#define H(h)cos((h)*6.3+vec3(0,23,21))*.5+.5
void main(void)
{
    vec4 O = glFragColor;
    vec2 C = gl_FragCoord.xy;
    O-=O;
    vec3 p,r=vec3(resolution.xy,1.0),
    d=normalize(vec3((C-.5*r.xy)/r.y,1));  
    for(
        float i=0.,g=0.,e,s;
        ++i<99.;
        O.rgb+=mix(r/r,H(log(s)),.7)*.05*exp(-.45*i*i*e))
    {
        p=g*d-vec3(.05*sin(time*.5),.1,.7);
        p=R(p,normalize(vec3(1,-2,2)),time*.5);
        s=4.;
        vec4 q=vec4(p,sin(time*.4)*.5);
        for(int j=0;j++<8;)
            q=abs(q),
            q=q.x<q.y?q.zwxy:q.zwyx,
            s*=e=1.35/min(dot(q,q),0.54),
            q=q*e-vec4(0,4,.8,3);
        g+=e=min(
            length(q.w)/s,
            length(cross(q.xyw,normalize(vec3(1,2,3))))/s-.0002
        );
    }
    O=pow(O,vec4(5));
    glFragColor = O;
 }

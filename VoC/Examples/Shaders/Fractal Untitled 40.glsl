#version 420

// original https://www.shadertoy.com/view/wlyfDG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define R(p,a,r)mix(a*dot(p,a),p,cos(r))+sin(r)*cross(p,a)
#define H(h)(cos((h)*6.3+vec3(0,23,21))*.5+.5)
void main(void) //WARNING - variables void (out vec4 O, vec2 C) need changing to glFragColor and gl_FragCoord.xy
{
    vec4 O=vec4(0);
    vec3 p,r=vec3(resolution,1.0),
    d=normalize(vec3((gl_FragCoord.xy-.5*r.xy)/r.y,1));  
    for(float i=1.,g=0.,e,s,a;
        ++i<99.;
        a=cos(i*i/80.),O.rgb+=mix(vec3(1),H(log(s)/5.),.5)*a*a/e/2e4
    )
    {
        p=g*d-vec3(-.8,.2,2);
        p=R(p,normalize(vec3(10,1,1)),time*.1);
    s=3.;
    for(int i=0;i++<5;p=abs(p)*e)
    p=vec3(8,4,2)-abs(p-vec3(9,4,2)),
    s*=e=8./clamp(dot(p,p),.1,7.);
  g+=e=min(length(p.xz),p.y)/s+.001;}
  glFragColor=O;
}

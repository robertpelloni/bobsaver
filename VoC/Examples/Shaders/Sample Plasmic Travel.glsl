#version 420

// original https://www.shadertoy.com/view/Mdyfz3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float m(vec3 p) 
{ 
    p.y+=1.5*sin(p.x+time*2.);
    p.z+=3.*time; 
    return length(.1*sin(p.x/1.5+p.y)+cos(p.zzx/4.))-.9; 
}

void main(void) //WARNING - variables void (out vec4 c,vec2 u) need changing to glFragColor and gl_FragCoord
{
    vec2 u = gl_FragCoord.xy;
    vec4 c;
    vec3 d=.9-vec3(u/.65,0)/resolution.x,o=d;
    for(int i=0;i<64;i++) o+=m(o)*d;
    c.rgb = abs(m(o*1.8)*vec3(.3+sin(o.x)/3.,.1,.1)+m(o*.5)*vec3(.1,.05,0))*(9.-o.y/3.);
    // Kind of fire flame effect
    //c.rgb = 1.*abs(m(o+d)*vec3(.3,.15,.1)+m(o*.5)*vec3(.1,.05,0))*(12.-o.x/2.);
    glFragColor=c;
}

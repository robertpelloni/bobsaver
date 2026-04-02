#version 420

// original https://www.shadertoy.com/view/ssVGWc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define R(p,a,r)mix(a*dot(p,a),p,cos(r))+sin(r)*cross(p,a)
#define H(h)cos((h)*6.3+vec3(0,23,21))*.5+.5

// https://www.iquilezles.org/www/articles/distfunctions2d/distfunctions2d.htm
float sdHexagon(vec2 p, float r)
{
    const vec3 k = vec3(-0.866025404,0.5,0.577350269);
    p = abs(p);
    p -= 2.0*min(dot(k.xy,p),0.0)*k.xy;
    p -= vec2(clamp(p.x, -k.z*r, k.z*r), r);
    return length(p)*sign(p.y);
}

void main(void)
{
    vec4 O=vec4(0);
    vec3 p,r=vec3(resolution.xy,1.0),
    d=normalize(vec3((gl_FragCoord.xy-.5*r.xy)/r.y,1));  
    float i=0.,g=0.,e,s;
    for(;++i<99.;){
        p=d*g;
        p=R(p,vec3(1),.3);
        p.z+=time*.2;
        p=asin(sin(p*4.));
        float sdf=sdHexagon(p.xy,2.);
        p.xy=vec2(sdf);
        s=3.;
        for(int i=0;i++<6;){
            p=vec3(3.2,6.8,5.2)-abs(p-vec3(3.4,4.8,2.4));                        
              p=p.x<p.y?p.zxy:p.zyx;
            s*=e=17.8/min(dot(p,p),11.8);
            p=abs(p)*e;
        }
        g+=e=abs(p.y)/s+.001;
        O.xyz+=(H(log(s)*.8)+.5)*exp(sin(i))/e*3e-5;
    }
    O*=O*O*O;
    glFragColor = O;
 }

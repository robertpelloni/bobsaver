#version 420

// original https://www.shadertoy.com/view/cs33Dj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
    "Construction" by @XorDev

    Fun fractal experiments.
    Let me know if you can find a fix for the flickery colors!

    Based loosely on "Flyby": https://www.shadertoy.com/view/cddGzs
    
    
    <300 chars playlist: shadertoy.com/playlist/fXlGDN
*/
void main(void) //WARNING - variables void (out vec4 O, vec2 I) need changing to glFragColor and gl_FragCoord.xy
{
    vec4 O = vec4(0.0);
    vec2 I = gl_FragCoord.xy;

    float d,i,l;
    for(vec3 r=vec3(resolution.xy,1.0),q,p=3.-vec3(time,O*=0.); l++<6e1; p+=normalize(vec3(I+I,r)-r)*d)
    for(q=p,q.yz*=mat2(.8,-.6,.6,.8),d=q.y,i=2.; i>.01; i*=.6)
        d=max(d,min(min(q=abs(mod(q,i*4.)-i-i)-i,q.y),q.z).x),
        O+=(cos(d*6e6+vec4(0,1,2,3))+2.)/7e2/exp(d*d*1e9);

    glFragColor=O;
}


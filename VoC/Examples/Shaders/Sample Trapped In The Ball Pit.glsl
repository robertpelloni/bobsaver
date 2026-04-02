#version 420

// original https://www.shadertoy.com/view/3ttBWN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define rot(a) mat2(cos(a), -sin(a), sin(a), cos(a))

void main(void) {
    vec3 l = normalize(vec3((gl_FragCoord.xy/resolution.xy-.5)*vec2(1.8, 1.), 1.9)),
    o = vec3(-time, time, -8.),
    p;
    
    l.yz *= rot(-2.2/2.);
    l.xy *= rot(3.14/4.);
    
    float d, t = 0., s = 0.;
    for(int i = 0; i < 40; i++){
        p = o+l*t;
        d = length(vec3(mod(p.xy, 1.8)-1.8*.5, p.z))-1.; 
        
        if(d < .002 || t > 40.) break;
        
        t += d * .95;
        s++;
    }
    
    vec2 k = floor(p.xy/1.8);
    vec3 c = .33+.34*cos(vec3(.6,.1,1.)*(k.x*52.+k.y*72.)*12.);

    glFragColor = vec4(1.-exp(-c*1.5*smoothstep(4., 1., s/10.)), 1.);
}

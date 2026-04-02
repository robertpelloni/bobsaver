#version 420

// original https://www.shadertoy.com/view/ftfSRB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define res resolution

float plot(vec2 uv, float sig, float amp, float lev){
    return 1./abs(amp*(uv.y-sig*lev));
}

void main(void) {
    
    vec2 uv = (2.*gl_FragCoord.xy-res.xy)/res.y;
    
    float t = .6*time + 1.4*uv.x * 6.28318;
    float d = .7*time;
    float f = sin(d+t); 
    f += sin(d+t*3.)/3.; 
    f += sin(d+t*5.)/5.; 
    f += sin(d+t*7.)/7.; 
    f += sin(t*9.)/9.; 
    f += sin(t*11.)/11.; 

    f = plot(uv, f, 150., .4);
    
    vec3 c = vec3(f*.2, f, f*.2);
 
   // float m = step(1.-abs(2.*(abs(uv.y)-(fract(time*.6)-fract(uv.y*8.)))), .01);
   
    vec2 v = fract(uv*5.2);
    v = 1./(17.*abs(v-.5));
    float m = clamp(dot(v, vec2(.12)), .0,.7);
    c += vec3(m*.8, m*.77, .0)*.8;
    
    glFragColor = vec4(c, 1.);
}

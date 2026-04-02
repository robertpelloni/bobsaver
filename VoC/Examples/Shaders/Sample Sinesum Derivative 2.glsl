#version 420

// original https://www.shadertoy.com/view/tltyWN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159265

#define _b 1.6

vec2 b(float t, vec2 v){
   return abs(fract(t*v)-.5)*2.;
}

float ff(float n, float n2, float n3, float amp){
 return ((sin(n)+1.)*(sin(n2)*(sin(n3))+1.)+log(((sin(PI+n)+1.)*(sin(PI+n2)+1.))+1.))*amp; 
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy;

    //vec3 col = 0.5 + 0.5*cos(time+uv.xyx+vec3(0,2,4));
    
    float a = 10.;
    float amp = 0.5;
    float d = .2;
    
    float time = time*0.04;

    float n = a*(time+distance(uv, _b*b(time,vec2(3.1,1.7))));
    float n2 = a*(time+distance(uv, _b*b(time,vec2(2.4,3.15))));
    float n3 = a*(time+distance(uv, _b*b(time,vec2(1.45,2.65))));
    
    float f = ff(n, n2, n3, amp);
    float f2 = ff(n+d, n2+d, n3+d, amp);
    
    n = a*(time+distance(uv, b(time,vec2(1.5,3.7))));
    n2 = a*(time+distance(uv, b(time,vec2(3.4,1.15))));
    n3 = a*(time+distance(uv, b(time,vec2(2.45,1.65))));
    
    f += ff(n, n2, n3, amp);
    f2 += ff(n+d, n2+d, n3+d, amp);
    
    float v = (f2-f)/d;

    glFragColor = vec4((1.-vec3(v*v))*vec3(0.,0.3,1.),1.0);
}

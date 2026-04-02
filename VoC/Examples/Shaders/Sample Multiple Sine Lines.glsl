#version 420

// original https://www.shadertoy.com/view/wdcSW7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define S(a,b,t) smoothstep(a,b,t)

vec3 getline (in vec2 uv, in float offs, in float t) {
    float ti = t*.5;
    uv.y = uv.y + sin(ti+uv.x+(offs*0.32)*cos(ti*1.3+sin(uv.y-uv.x*.85)))*2.;
    return S(0.08,0.001, distance(uv.y, 0.))*vec3(.4,.7,.9)*S(0.8,0.1,mod((uv.x*.1+(offs*.1))+t,2.)-1.);
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    
    vec2 ms = mouse*resolution.xy.xy/resolution.xy;
    float  t = time+(2.*ms.x)+(.5*ms.y);
    uv *= 5.;
    
    vec3 col = vec3 (0.);
    for (float i=0.;i<=16.;i++) {
        col += getline(uv,i+3.2,t);
    }    
    
    glFragColor = vec4(col,1.0);
}

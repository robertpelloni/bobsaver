#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main()
{
    float v,t=v=.0005;
    vec3 cen=gl_FragCoord.xyz;
    cen.xy=((cen.xy/resolution.xy)-0.5)*resolution.xy;
    for (float s=.0; s<2.; s+=.01) {
        vec3 p=s*(cen+vec3(.6,.6,.6))*t+vec3(.1,.2,fract(s+floor(time*25.)*.01));
        for (int i=0; i<8; i++) p=abs(p)/dot(p,p)-.8;
        v+=dot(p,p)*t;
    }
    glFragColor=vec4(v, v, v * 5.0, 1.0);
}

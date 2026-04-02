#version 420

// original https://www.shadertoy.com/view/Nll3z2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define res resolution
#define ft float

ft hm(vec2 uv, vec2 m){
    ft a = dot(uv,uv);
    ft b = sin(.6*time+uv.x/a/m.x)-sin(uv.y/a/m.y);
return abs(b*1.4);
}

void main(void)
{
    vec2 uv = (2.*gl_FragCoord.xy-res.xy)/res.y;
    vec2 m = vec2(2.3);
    ft a = hm(uv, m);
    for(ft i; i < 6.; i++){
    uv = abs(uv/hm(uv,m+i*.2)-.4*mouse);
    }
    glFragColor = vec4(1.-1./uv.xyy,1.0);
}

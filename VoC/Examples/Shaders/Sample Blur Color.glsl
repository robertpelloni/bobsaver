#version 420

// original https://www.shadertoy.com/view/wlsyDH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec4 o=vec4(0);
    vec3 u=normalize(vec3(2.*gl_FragCoord.xy-resolution.xy,resolution.y));
    for(int i=0;i<6;i++){
        u.x+=sin(u.z+time*.1);
        u.y+=cos(u.x+time*.1);
        o=max(o*.9,cos(3.*dot(u,u)*vec4(.3,.1,.2,0)));
    }
    glFragColor = o;
}

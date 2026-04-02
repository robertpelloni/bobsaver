#version 420

// original https://neort.io/art/bua3ims3p9f7gige8i8g

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

#define FC gl_FragCoord
#define r resolution
#define o glFragColor
#define t time

void main(void) {
    vec2 p=(FC.xy*2.0-r)/r.y;
    vec3 R=abs(normalize(vec3(p,2.5)));
    if(R.x>R.y)R.xy=R.yx;
    vec2 u=(vec2(t,0)+R.zx/R.y)*3.,i=floor(u);
    u-=i;
    if(u.y>u.x)u=u.yx;
    float d=min(1.-u.x,u.y),v=fract(sin(dot(i,vec2(8,9)))*1e4);
    o=vec4(vec3(v,0.3,1)*9.*smoothstep(0.,0.8,d)*v+0.01/d,1.);
}

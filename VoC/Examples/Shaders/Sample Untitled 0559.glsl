#version 420

// original https://www.shadertoy.com/view/wd2czc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define t time
#define r resolution.xy

void main(void) {
    vec3 c;
    float l,z=t;
    for(float j=0.9;j<4.3;j+=.3) {
        for(int i=0;i<3;i++) {
            vec2 uv,p=gl_FragCoord.xy/r;
            uv=p;
            p-=.5;
            p.x*=r.x/r.y;
            z+=0.3;
            l=length(p);
            uv+=p/l*(sin(z)+(j/0.3))*abs(sin((l*j)+z*(j+0.6)));
            c[i]=.02/length(abs(mod(uv,1.)-2.7/j));
        }
    }
    glFragColor=vec4(c/l,t);
}

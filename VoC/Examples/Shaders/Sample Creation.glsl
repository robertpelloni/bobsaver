#version 420

// original https://www.shadertoy.com/view/XsXXDn

uniform float time;
uniform vec2 resolution;

out vec4 glFragColor;

// http://www.pouet.net/prod.php?which=57245

#define t time
#define r resolution.xy

void main(){
    vec3 c;
    float l,z=t;
    for(int i=0;i<3;i++) {
        vec2 uv,p=gl_FragCoord.xy/r;
        uv=p;
        p-=.5;
        p.x*=r.x/r.y;
        z+=.07;
        l=length(p);
        uv+=p/l*(sin(z)+1.)*abs(sin(l*9.-z*2.));
        c[i]=.01/length(abs(mod(uv,1.)-.5));
    }
    glFragColor=vec4(c/l,t);
}

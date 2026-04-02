#version 420

// original https://www.shadertoy.com/view/Nds3zn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
|--------------------------------------------------------------------------
| Rémy Dumas
|--------------------------------------------------------------------------
|
| Twitter: @remsdms
| Portfolio: remydumas.fr
|
*/

#define t time
#define r resolution.xy

/*
|--------------------------------------------------------------------------
| Main
|--------------------------------------------------------------------------
|
| Sandbox and sometimes something good
|
*/

void main(void) {
    vec3 c;
    float l,z=t;
    for(int i=0;i<3;i++) {
        vec2 uv,p=gl_FragCoord.xy/r;
        p-=.5;
        p.x*=r.x/r.y;
        uv=p;
        l=length(p);
        uv+=p/l*(sin(z*l))*abs(sin(l*9.-z*2.));
        c[i]=.1/length(uv);
    }
    glFragColor=vec4(c,t);
}

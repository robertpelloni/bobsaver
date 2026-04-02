#version 420

// original https://www.shadertoy.com/view/tllfzB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define r resolution.xy
vec3 f(vec2 p) {
    p.y+=cos(time*.25)*.3; // move camera up and down;
    p.x=abs(p.x+.3); // offset and mirror x axis
    p*=mat2(.7,.7,-.7,.7); // rotate ~45deg
    float y=1.-abs(p.y*3.),l=1.-length(p), m=1e2; // used for: y=horizon, l=light, m=orbit trap
    p=fract(vec2(p.x/p.y,1./p.y+time*1.*sign(p.y))*.5); // 3D projection, tiling and and forward movement
    for (int i=0; i<18; i++) p=abs(p*1.5)/(p.x*p.y)-2.,m=min(m,abs(p.y)+abs(.5-fract(p.x*.5+time))); // fractal & orbit trap
    m=exp(-10.*m); // something like inverting and compressing the orbit trap result
    return mix(min(vec3(1.),vec3(m,m*m,m*m*m)*3.+p.x*p.x*.1),vec3(1,.5,.3),y)+l*l*l*.8; // coloring
}
void main(void)
{
    vec4 c=vec4(0);
    vec2 u = (gl_FragCoord.xy-r*.5)/r.y,d;
    // antialiasing
    for (float i=-4.; i<4.; i++) for (float j=-4.; j<4.; j++) d=vec2(i,j)*.2/r,c.rgb+=f(u+d)/64.;
    glFragColor=c;
}

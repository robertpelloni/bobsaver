#version 420

// original https://www.shadertoy.com/view/Md2GWW

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void) {
    float t=-.6*time,u=.5*cos(t),s=.5*sin(t);
    vec2 z = 3.*gl_FragCoord.yx/resolution.yx-1.5;
    vec3 v=vec3(1),d=v;
    for(int i=0;i<9;i++){
        z=vec2(u-u*u+z.x*z.x-z.y*z.y,smoothstep(-.5,.0,cos(t*.4))*(s-s*s)+2.*z.x*z.y);
        d=min(d,vec3(abs(z.y*z.x),dot(z,z),fract(z)));
    }
    d = pow(d.x,u*s)*mix(v,2.*d,.6*d.z)-1.4*smoothstep(.0,.003,d.y-.2*abs(s)*u);
    glFragColor.rgb = d*d;
}

#version 420

// original https://www.shadertoy.com/view/3djyWd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec4 O = glFragColor;
    vec2 C = gl_FragCoord.xy;

    vec2 q=C.xy/resolution.y-.4;
    vec3 p,d=normalize(vec3(q,-2.-dot(q,q)*3.)).xzy;
    d.xz+=sin(d.xz*9.-time)*8.;
    float t,e,i;
    for(i=0.;i<30.;i++){
        p=d*t;
        t+=e=(length(vec3(mod(p.xz,4.)-2.,p.y+2.)))*.05;
    }
    O=vec4(cos(vec3(5,6,9)+d)/30./e,1);

    glFragColor = O;
}

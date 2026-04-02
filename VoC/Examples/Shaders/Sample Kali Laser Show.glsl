#version 420

// original https://www.shadertoy.com/view/Xd2GRD

uniform float time;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    float t=time*.1;
    vec2 uv = gl_FragCoord.xy / resolution.xy-.5;
    vec2 ouv=uv;
    uv.x*=resolution.x/resolution.y;
    vec3 rd=normalize(vec3(uv,2.));
    rd.xy*=mat2(cos(t),sin(t),-sin(t),cos(t));
    vec3 ro=vec3(t+sin(t*6.53583)*.05,.01+sin(t*352.4855)*.0015,-t*3.);
    vec3 p=ro;
    float v=0., td=-mod(ro.z,.005);
    for (int r=0; r<150; r++) {
        v+=pow(max(0.,.01-length(abs(.01-mod(p,.02))))/.01,10.)*exp(-2.*pow((1.+td),2.));
        p=ro+rd*td;
        td+=.005;
    }
    glFragColor = vec4(v,v*v,v*v*v,0.)*8.*max(0.,1.-length(ouv*ouv)*2.5);
}

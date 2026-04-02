#version 420

// original https://www.shadertoy.com/view/Xl2BzW

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define COUNT 218.0

void main(void)
{
    float t = time*6.28*.1;
    vec2 p = gl_FragCoord.xy - resolution.xy*.5;
    vec2 uv = p / resolution.xx*15.;
    
    float d = length(uv);
    float f = 0.;
    float phase = t;
    float dir = 1.;
    float a = 0.;
    float len = -d*(cos(t)*.2+.2);
    for(float i = 0.; i<COUNT; i+=1.){
        float p = phase +(sin(i+t)-1.)*.05+len;
        a = dot(normalize(uv), normalize(vec2(cos((p)*dir), sin((p)*dir))));
        a = max(0., a);
        a = pow(a, 10.);
        dir*=-1.;
        phase+=mod(i,6.28);
        f += a;
        f = abs(mod(f+1., 2.)-1.);
    }    
    f+=1.7-d*(.7+sin(t+dot(normalize(uv), vec2(1., 0.))*12.)*.02);
    f = max(f, 0.);
    vec3 c = mix( vec3(0.), vec3(1., .9, .6), f);
    c = min(max(c, 0.),1.);
    c = 1.0-vec3(.6, .4, .3)*3.*(1.0-c);
    glFragColor = vec4(c,1.0);
}

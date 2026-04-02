#version 420

// original https://www.shadertoy.com/view/lt2BDD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//Ethan Alexander Shulman 2018

float hash(vec2 p) {
    return fract(dot(p+vec2(.36834,.723), normalize(fract(p.yx*73.91374)+1e-4))*7.38734);
}

void main(void)
{
    vec2 u = gl_FragCoord.xy;
    float time = mod(time,999999.);
    vec3 ro = vec3(sin(time*.04)*8.,cos(time*.06)*5.,time), rd = normalize(vec3((u*2.-resolution.xy)/resolution.x,1.));
    vec4 s = vec4(0.);
    for (float i = 1.; i < 256.; i+=i*.1) {
        vec3 p = abs(ro+rd*(i+hash(u+i))),
            lp = mod(p,20.)-10., fp = floor(p/20.);
        float ld = 1e6,
        d = length(lp)-8.;
        float la1 = atan(lp.y,lp.x)+time;
        s += vec4(sin(la1+fp.z*2.2834),cos(la1+fp.x*.73973),-sin(la1+fp.y*.8594),1)*.04*max(0.,2.-abs(d));
        if (s.w >= 1.) break;
    }
    glFragColor = mix(vec4(0),s,s.w);
}

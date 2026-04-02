#version 420

// original https://www.shadertoy.com/view/3dl3WX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//Ethan Alexander Shulman 2019, made on livestream at twitch.tv/ethanshulman

float triwave(float x) {
    return x*2.-max(0.,x*4.-2.);
}

#define time time

void main(void)
{
    vec2 u = gl_FragCoord.xy;
    vec2 uv = (u*2.-resolution.xy)/resolution.x;

    float t1 = fract(time*.2)*10.,
    t2 = fract(time*.2+0.5)*10.;
    float g1 = length(max(abs(mod(abs(uv)*t1*t1,2.)-1.)-.8,0.)),
        g2 = length(max(abs(mod(abs(uv)*t2*t2,2.)-1.)-.8,0.)),
        s1 = max(.4,(1.0-t1*.1*.6)-g1*10./t1),
        s2 = max(.4,(1.0-t2*.1*.6)-g2*10./t2);
    glFragColor = vec4(mix(s1,s2,clamp((triwave(fract(time*.2+0.5))*2.-1.)*2.,-1.,1.)*.5+.5));
}

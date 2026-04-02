#version 420

// original https://www.shadertoy.com/view/tss3Dj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//Ethan Alexander Shulman 2019, made on livestream at twitch.tv/ethanshulman

#define time time

float voronoi(vec2 u, float i) {
    #define l(i) length(fract(abs(u*.01+fract(i*vec2(1,8))+sin(u.yx*.2+i*8.)*.02+sin(u*.06+1.6+i*6.)*.1))-.5)
    return l(i);
}
float triwave(float t) {
    return t*2.-max(0.,t*4.-2.);
}

void main(void)
{
    vec2 u = gl_FragCoord.xy;
    vec2 uv = (u*2.-resolution.xy)/resolution.y;
    float scal = 10.+triwave(fract(time*.02))*200.;
    vec3 s = vec3(0);
    for (int i = 0; i < 8; i++) {
        s += (sin((float(i+2)+(abs(uv.xyx)+abs(uv.yxy)*.4)*.02*scal*float(i+1))*vec3(.5,1.2,4.2)+voronoi(uv*scal*float(i+1),float(i)/8.0)*pow(float(i+2),2.)-time*pow(float(i+1),1.2))*.5+.5)/float(i+1);
    }
    s = pow(s*.35,vec3(2.));
    glFragColor = vec4(s,1);
}

#version 420

// original https://www.shadertoy.com/view/3sKBDd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*Ethan Alexander Shulman 2020 - xaloez.com
4k 60fps video https://www.youtube.com/watch?v=_JyfhJxrkHg
4k wallpaper xaloez.com/art/2020/LightDance.jpg*/

mat2 r2(float a) {
    float s = sin(a), c = cos(a);
    return mat2(c,-s,s,c);
}

void main(void)
{
    float time = time;
    vec2 uv = (gl_FragCoord.xy*2.-resolution.xy)/resolution.y;

    vec3 rp = vec3(1,1,time),
        rd = normalize(vec3(uv.xy,1.)),
        c = vec3(0);
    rp += rd*10.;
    for (int i = 0; i < 24; i++) {
        vec3 tp = rp+sin(rp.yzx*.2+time*vec3(1,1,0))+cos(rp.zxy*.4)*.4;
        float dst = length(mod(abs(tp),2.)-1.)-.2;
        c += max(0.,1.-abs(dst))*abs(sin(tp)+sin(tp.zxy*.7)+sin(tp.yzx*.9));
        rp += rd*(dst+0.01);
    }
    glFragColor = vec4(pow(c*.05,vec3(2.)),1);
}

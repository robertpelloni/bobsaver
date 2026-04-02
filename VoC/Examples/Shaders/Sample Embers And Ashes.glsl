#version 420

// original https://www.shadertoy.com/view/Wd3BD7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*Ethan Alexander Shulman 2020 - xaloez.com
3840x2160 60fps video https://www.youtube.com/watch?v=2ISSvdhVfwM
3840x2160 wallpaper xaloez.com/art/2020/EmbersandAshes.jpg*/

void main(void)
{
    float time = time;
    vec2 uv = (gl_FragCoord.xy*2.-resolution.xy)/resolution.y;
    
    float s = 0.;
    for (float p = 0.; p < 1000.; p++) {
        #define R3P 1.22074408460575947536
        vec3 q = fract(.5+p*vec3(1./R3P,1./(R3P*R3P),1./(R3P*R3P*R3P)));
        float a = p*.001+time*(.01+q.z*.1);
        vec2 x = q.xy*mat2(sin(a*2.1),sin(a*4.13),sin(a*8.16),sin(a*4.18));
        float l = length(x-uv.xy);
        s += sin((l-q.z)*10.)/(1.+max(0.,l-.01)*200.);
    }
    glFragColor = mix(vec4(.05,.08,.1,1),vec4(1,.5,.4,1),max(0.,s*.4));
}

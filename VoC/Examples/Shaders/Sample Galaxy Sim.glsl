#version 420

// original https://www.shadertoy.com/view/WtKSzd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Branched from: https://www.shadertoy.com/view/XlfGRj
// Star Nest by Pablo Roman Andrioli
// This content is under the MIT License.

#define iterations 17
#define formuparam 0.53
#define volsteps 20
#define stepsize 0.1
#define tile   0.850
#define speed  0.010 
#define brightness 0.0015
#define darkmatter 0.300
#define distfading 0.730
#define saturation 0.850

void main(void)
{
    vec2 uv = (-1.+2.*gl_FragCoord.xy/resolution.xy)*vec2(resolution.x/resolution.y,1.);
    float hTime = time*0.5;
    float animValue = smoothstep(0.5,3.2,0.7+hTime*0.1);
    vec3 dir = vec3(uv*animValue*0.5,1.);
    float time = hTime*speed+.25;
    float value = max(-5.0+hTime*0.2,0.);
    float a1 = .5+hTime*1e-4;
    float a2 = .8-hTime*3e-4;
    mat2 rot1 = mat2(cos(a1),sin(a1),-sin(a1),cos(a1));
    mat2 rot2 = mat2(cos(a2),sin(a2),-sin(a2),cos(a2));
    dir.xz *= rot1;
    dir.xy *= rot2;
    vec3 from = vec3(0.,0.,sin(-0.15+hTime*0.005)*-0.30);
    float animTime = 0.7 + 0.27 * max(-4.0+hTime*0.2,0.);
    animTime += value;
    from += vec3(cos(animTime)*0.3,sin(animTime*0.73)*0.2,0.);
    from.xz *= rot1;
    from.xy *= rot2;
    from.x -= 1e-1;
    float s = 1e-1;
    float fade = 1.;
    vec3 v = vec3(0.);
    for (int r = 0; r < volsteps; r++)
    {
        vec3 p = from+s*dir*.5;
        p = abs(vec3(tile)-mod(p,vec3(tile*2.)));
        float pa = 0.;
        float a = 0.;
        for (int i=0; i<iterations; i++)
        { 
            p = abs(p)/dot(p,p)-formuparam;
            a += abs(length(p)-pa);
            pa = length(p);
        }
        float dm = max(0.,darkmatter-a*a*1e-3);
        a *= a*a;
        if (r > 6)
        {
            fade *= 1.-dm;
        }
        v += fade;
        v += vec3(s,s*s,s*s*s*s)*a*brightness*fade;
        fade *= distfading;
        s += stepsize;
    }
    v = mix(vec3(length(v)),v,saturation);
    glFragColor = vec4(v*1e-2,1.);    
}

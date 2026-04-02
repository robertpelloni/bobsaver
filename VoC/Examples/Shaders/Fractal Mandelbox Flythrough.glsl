#version 420

// original https://www.shadertoy.com/view/tsBGzV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec3 r = normalize(vec3(gl_FragCoord.xy / resolution.y - vec2(.5), 1.)),
         p = vec3(-.44, .11,-15. + time);
    for(float i = .0; i < 200.; i++){
        vec4 o = vec4(p, 1), q = o;
        for(int i = 0;i < 20;i++){
            o.xyz = clamp(o.xyz, -1., 1.)*2. - o.xyz;
            o = o * clamp(max(.25 / dot(o.xyz, o.xyz), .25), 0., 1.);
            o = o * (vec4(2.79) / .25) + q;
        }
        float d = (length(o.xyz) - 1.) / o.w - pow(2.79, -9.);
        if(d < .0001){
            break;
        }
        p += r * d;
        glFragColor.rgb = vec3(1. - i / 100.);
    }
}

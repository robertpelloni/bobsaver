#version 420

// original https://www.shadertoy.com/view/4tdyzB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;
uniform sampler2D backbuffer;

out vec4 glFragColor;

float cross2d(vec2 a, vec2 b)
{
    return a.x * b.y - a.y * b.x;
}

vec2 rot90(vec2 a)
{
    return vec2(a.y, -a.x);
}

#define CELL_SIZE 12. // try other values

vec2 trans(vec2 p)
{
    p -= .5 * resolution.xy;
    p /= CELL_SIZE;
    return p;
}

vec2 field(vec2 d)
{
    return d / pow(dot(d,d),1.5);
}

vec2 polar(float a)
{
    return vec2(cos(a), sin(a));
}

void main(void) //WARNING - variables void ( out vec4 O, in vec2 UU ) need changing to glFragColor and gl_FragCoord
{
    vec2 UU = gl_FragCoord.xy;
    vec4 O = glFragColor;

    vec2 U = trans(UU);
    
    vec2 u = -.5+mod(U+.5, 1.);
    
    float rad = (6. + 2.*sin(time*.6));
    vec2 off = rad * polar(7.*time/rad);
    vec2 f = field(U - off) + field(U + off);
    f += (1. + .5 * sin(time * .6)) * field(U - trans(mouse*resolution.xy.xy));
    
#define bord(w,x) smoothstep(w+.06,w-.06,x);
    
    float w = max(.0,.3*sqrt(log(1.+length(f))));
    float o = bord(w,abs(dot(u, normalize(f))));
    float p = bord(w,abs(cross2d(u, normalize(f))));
    vec3 oc=vec3(1.,0.,.5), pc=vec3(0.,1.,.5); // try some other fantastic colors!!!
    O.rgb = o*oc + p*pc;
    #if 0
    vec4 old = texture(backbuffer, UU/resolution.xy);
    O.g = mix(O.g, old.b, .2);
    #endif

    glFragColor = O;
}

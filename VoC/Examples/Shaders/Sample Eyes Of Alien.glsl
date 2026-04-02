#version 420

// original https://www.shadertoy.com/view/Xt33WS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Some codes stolen from fernozzle
// Flashy greets to the following groups:
// Adinpsz, Alcatraz, Andromeda, ASD,
// AttentionWhore, Black Maiden, CNCD, Cocoon,
// Conspiracy, Darklite, Da Jormas, Desire,
// Digital Dynamite, DSS, Ephidrena, Epoch,
// Fairlight, Farbrausch, Fnuque, Ghostown,
// Halcyon, Haujobb, Holon, Kewlers,
// Lemon, LNX, Logicoma, Loonies,
// Mercury, MFX, Nonoil, Nuance,
// Pittsburgh Stallers, Primitive, RGBA, Satori,
// Still, Stroboholics, SystemK, S!P,
// TBC, TBL, The Adjective, TPOLM,
// United Force, Vovoid, and all groups I've forgotten!
#define ITERATIONS 20

float hash(float x)
{
    return fract(sin(x*.1337)*1337.666);
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy - 0.5;
    uv.x *= resolution.x/resolution.y; //fix aspect ratio
    
    float time = time * 2. + 15.;
    vec2 res = resolution.xy;
    
    float len = dot(uv, uv) * 9.0 - 2.9;
    
    vec3 z = sin(time * vec3(.13, .0, .17));
    for (int i = 0; i < ITERATIONS; i++) {
        z += cos(z.zxy + uv.yxy * float(i) * len);
    }
    
    float val = z.r * .1 + .1;
    val -= smoothstep(.1, -.3, len) * 1.5 + len * .3 - .4;
    glFragColor = vec4(vec3(max(val, .1)), 1.);
}

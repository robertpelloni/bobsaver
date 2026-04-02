#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/Wtc3D8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define UI0 1597334673U
#define UI1 3812015801U
#define UI2 uvec2(UI0, UI1)
#define UI3 uvec3(UI0, UI1, 2798796415U)
#define UIF (1.0 / float(0xffffffffU))

#define SCALE 12.
#define PURPLE (vec3(92., 25., 226.)/255.)

const vec3[3] colors = vec3[](
                        vec3(92., 197., 187.)/255., // cyan
                        vec3(240., 221., 55.)/255., // yellow
                        vec3(253., 87., 59.)/255.); // red
    
// Hash by Dave_Hoskins
float hash12(vec2 p)
{
    uvec2 q = uvec2(ivec2(p)) * UI2;
    uint n = (q.x ^ q.y) * UI0;
    return float(n) * UIF;
}

// Distance function by iq
float sdBox( in vec2 p, in vec2 b )
{
    vec2 d = abs(p)-b;
    return length(max(d,vec2(0))) + min(max(d.x,d.y),0.0);
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy / resolution.y;
    // first set of grid uv
    vec2 auv = uv * SCALE;
    vec2 _auv = fract(auv);
    // second set of grid uv offset by first grid uv center
    vec2 buv = uv * SCALE - .5;
    vec2 _buv = fract(buv);
    // time factor
    float t = time;

    vec3 col = vec3(0.);
    
    // random color index for each cell in the grid
    float ah = hash12(floor(auv + 647.));
    // rounded box for first grid uv
    float abox = smoothstep(.1, .05, sdBox(_auv - .5, vec2(.305)) - .12)
        * (.75 + .25 * sin(t + 588. * ah)) * 1.1 + .1;
    // box color oscillating between light and dark
    vec3 aboxCol = colors[int(3. * hash12(floor(auv) + 378. + t * .4))];
    // random number for each second grid cell
    float bh = hash12(floor(buv + 879.));
    // rounded box for the second offset grid
    float bbox = smoothstep(.1, .05, sdBox(_buv - .5, vec2(.305)) - .12)
        * (.75 + .25 * sin(t + 261. * bh)) * 1.1 + .1;
    // oscillate the color, but give it a darker shade than the first grid,
    // which in turn offsets the color in the first grid
    vec3 bboxCol = colors[int(3. * hash12(floor(buv) + 117. - t * .8))];
    
    // mix grid box colors based on their respective alpha
    col = mix(col, vec3(abox) * aboxCol, abox);
    col = mix(col, vec3(bbox) * bboxCol, .5 * bbox);
    col = mix(col * 1.25, PURPLE, 1. - (abox + bbox) * .5); // purple bg

    glFragColor = vec4(col, 1.0);
}

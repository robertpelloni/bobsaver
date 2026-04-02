#version 420

// original https://www.shadertoy.com/view/7scczB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define TURN (6.283185307)
#define HEX(x) (vec3((x >> 16) & 255, (x >> 8) & 255, x & 255) / 255.)

vec3 color(float r, float aa) {
    r = fract(r);
    float mix0 = smoothstep(0., aa, r);
    float mix1 = smoothstep(0., aa, r - 0.25);
    float mix2 = smoothstep(0., aa, r - 0.5);
    float mix3 = smoothstep(0., aa, r - 0.75);
    
    vec3 color0 = HEX(0x009BE8);
    vec3 color2 = HEX(0xfff100);
    vec3 color1 = HEX(0xEB0072);
    vec3 color3 = HEX(0x010a31);
    
    return (
        color0 * (mix0 - mix1) +
        color1 * (mix1 - mix2) +
        color2 * (mix2 - mix3) +
        color3 * (mix3 - mix0 + 1.)
    );
}

#define ZIGZAG(x) 1. - abs(1. - 2. * fract(x))

// Overall speed of the animation. 1.0 = loop once every second, 0.5 = loop once every 2 seconds, etc.
#define SPEED 1./2.

// How many dots in a circle.
#define ANGLEMULTI 15.

// How thick each ring should be.
#define RINGWIDTH 4.75
// How spaced out the rings should be.
#define RINGSPACE 1.4
// How large each dot should be. (max 1 or else the circles get stuck together)
#define DOTRADIUS 0.7

// How many rings of dots in total to render.
// The outer few rings migth be out of render range.
#define DEPTH 64.
// How many rings to zoom in per loop. Should be an even integer because of the stagger.
#define ZOOMSPEED 6.

// How distance-dense the colors should be.
#define SPIRALDIST 0.10
// How many loops of colors the spiral should do per rotation.
#define SPIRALANGLE 2.
// How fast the spiral's colors should move.
#define SPIRALSPEED -00.

// Wthether or not to smooth the outline of the dots and colors.
#define ANTIALIAS 1

vec2 angleVec(float angle) {
    return vec2(cos(angle), sin(angle));
}

void main(void)
{
    float t = fract(time * SPEED);
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (2. * gl_FragCoord.xy - resolution.xy) / length(resolution.xy);
    
    float angle = atan(uv.y, uv.x) / TURN;
    vec2 cbcr = vec2(0);
    
    float ioffset = mod(t * ZOOMSPEED, 2.) * RINGSPACE;

    for (float i = 0.; i < DEPTH; i++) {
        float alpha = clamp(ioffset + i - 2., 0., 1.);
        float z = (DEPTH - i) * RINGSPACE - ioffset - 1.;
        alpha *= clamp(z * 2., 0., 1.);
        float stagger = 0.5 * step(1., mod(i, 2.));
        float layerAngle = angle * ANGLEMULTI + stagger;
        float layerRound = (round(layerAngle) - stagger) / ANGLEMULTI;
        float layerAngleDist = ZIGZAG(layerAngle);
        float layerDist = (1. -
            log(length(uv) * z * RINGSPACE)
        ) * RINGWIDTH;
        
#if ANTIALIAS
        float layerV = smoothstep(
            DOTRADIUS, DOTRADIUS - 1.5 * fwidth(layerDist),
            length(vec2(layerDist,layerAngleDist))
        );
#else
        float layerV = step(
            layerDist * layerDist + layerAngleDist * layerAngleDist, DOTRADIUS
        );
#endif
        
        vec2 colLayer = angleVec((
            layerRound * SPIRALANGLE + z * SPIRALDIST + t * SPIRALSPEED
        ) * TURN);
        //colLayer = angleVec(i);
    
        cbcr = mix(cbcr, colLayer, layerV * alpha);
    }

    // Time varying pixel color
    float bgv = step(0.5, ZIGZAG(2.2 * log(length(uv))));
    bgv = mix(bgv, 1. - bgv, step(0.5, ZIGZAG(angle * 12.0)));
    vec3 col = mix(
        vec3(1), HEX(0xC4D7F0),
        bgv
    );
#if ANTIALIAS
    vec3 rawcol = color(atan(cbcr.y, cbcr.x) / TURN, 0.2);
#else
    vec3 rawcol = color(atan(cbcr.y, cbcr.x) / TURN, 0.0);
#endif
    col = mix(
        col, rawcol,
        min(1.0, length(cbcr))
    );

    // Output to screen
    glFragColor = vec4(col,1.0);
}

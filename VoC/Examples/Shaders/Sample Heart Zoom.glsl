#version 420

// original https://www.shadertoy.com/view/wlcfWS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float pixels = 15.0;

bool inHeart(vec2 coord) {
    vec2 c = (coord/pixels-.5) * 2.5;
    float lhs = dot(c,c) - 1.0;
    return lhs*lhs*lhs < c.x*c.x * c.y*c.y*c.y;
}

void main(void) {
    float tScale = exp(mod(time, log(pixels)));
    vec2 uv = fract(vec2(0.5) + (gl_FragCoord.xy/resolution.x - vec2(0.5, 0.25)) * 2.0 / tScale);
    
    // in-heart color
    vec3 col = vec3(1.0, 0.0, 0.0);
    
    // stop if pixels get too small, sampling could probably fix this
    float scale = tScale * resolution.x;
    while (scale > 7.0) {
        if (inHeart(floor(uv*pixels) + vec2(.5, .6))) {
            uv = fract(uv * pixels);
        } else {
            col = vec3(1.0, 0.6, 0.75);
            break;
        }
        scale /= pixels;
    }
    
    glFragColor = vec4(col,1.0);
}

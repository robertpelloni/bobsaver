#version 420

// original https://www.shadertoy.com/view/7sXyRl

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float nsin(float n) {
    return sin(n) * .5 + .5;
}

float rnd21(vec2 p) {
    p = fract(p * vec2(233.34, 851.73));
    p += dot (p, p + 23.45) ;
    return fract(p.x * p.y);
}

void main(void) {
    // normalize
    vec2 uv = gl_FragCoord.xy/resolution.xy;

    // grid uv
    float gridSize = 20.;
    float aspect = resolution.y / resolution.x;
    vec2 gUv = vec2(uv.x * gridSize, uv.y * (gridSize * aspect));
    
    // move grid
    gUv += time;
    
    // grid id
    vec2 id = floor(gUv);
    float rndById = rnd21(id);
    
    // pixel fade
    vec3 col = vec3 (0.8, 0.1, 0.4);
    col *= nsin((time * 4.) * rndById);

    glFragColor = vec4 (col, 1.0);
}

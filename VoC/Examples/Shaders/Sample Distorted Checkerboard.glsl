#version 420

// original https://www.shadertoy.com/view/3d3BRn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define VERTICAL_CHECKERS       22.
#define CHECKERS_DIFF           6.5
#define CHECKER_BORDER            0.02
#define BORDER_COLOR            vec3(0.1, 0.1, 0.1)

#define ANGULAR_SPEED 0.2
#define ANGULAR_ADD   0.5

//  Function from Iñigo Quiles
//  https://www.shadertoy.com/view/MsS3Wc
vec3 hsb2rgb(in vec3 c) {
    vec3 rgb = clamp(abs(mod(c.x * 6.0 + vec3(0.0,4.0,2.0),
                             6.0) -3.0 ) -1.0,
                     0.0,
                     1.0 );
    rgb = rgb * rgb * (3.0 - 2.0 * rgb);
    return c.z * mix(vec3(1.0), rgb, c.y);
}

vec2 rot(in vec2 p, in float a) {
    float s = sin(a);
    float c = cos(a);
    mat2 m = mat2(c, -s, s, c);
    return m * p;
}

vec4 toCheckers(in vec2 p) {
    // Rescale to (0,0) - (1,1)
    p /= resolution.xy;
    // Distort
    p += 0.05 * sin(p *12.);
    // Move (0,0) to center
    p -= 0.5;
    // Proportional x
    p.x *= resolution.x / resolution.y;
    // Tiles
    p *= VERTICAL_CHECKERS + CHECKERS_DIFF * sin(time);
    //p *= 5.;
    p = rot(p, time * ANGULAR_SPEED + sin(time * ANGULAR_ADD));
    
    return vec4(
        fract(p.x),
        fract(p.y),
        floor(p.x),
        floor(p.y));
}

void main(void) {
    vec4 c = toCheckers(gl_FragCoord.xy);
    
    // smothness from left-bottom
    float lb = smoothstep(CHECKER_BORDER, 0.0, min(c.x, c.y));
    // smoothness from upper-right
    float ur = smoothstep(1.0 - CHECKER_BORDER, 1.0, max(c.x, c.y));
    // total smoothness
    float borderFactor = max(lb, ur);
    // light or dark?
    float isLight = mod(c.z + c.w, 2.);
    // border and inner colors
    vec3 borderColor = BORDER_COLOR;
    vec3 innerColor = hsb2rgb(vec3(
        mod((c.z + c.w + time * 4.)/22., 3.),
        smoothstep(-1.6, 1., sin((c.z + c.w) / 12.1 + time * 1.3)),
        .7 + 0.3 * sin(c.z - c.w + time * 3.7)));
    
    glFragColor = vec4(
        mix(innerColor, borderColor, borderFactor),
        1.0);
}

#version 420

// original https://www.shadertoy.com/view/tl3cD2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float PI = 3.14159265358979;
const vec3 colA = vec3(1.0, 0.7, 0.9);
const vec3 colB = vec3(1.0, 0.5, 0.6);

// xor-ish behavior for floats
float flXor(float x, float y) {
    return x + y - 2. * (x * y);
}

// folds 0>1>2>3>4... to 0>1<0>1<0...
float fold(float x) {
    return abs(1. - mod(x, 2.));
}

void main(void)
{
    // Scales pixel coordinates, so that
    // the center is distance 0 and
    // diagonals are distance 1
    vec2 uvR = 2. * gl_FragCoord.xy - resolution.xy;
    vec2 uv = uvR / length(resolution.xy);

    float lenSq = log(length(uv));
    float lenAdd = -0.2;
    // logx/dx = 1/x
    float blur = 6.0 / max(0.1, length(uvR));
    float angle = atan(uv.y, uv.x) / PI;
    
    float timeScale = time * PI * 0.125;
    
    float spiral1 = smoothstep(0.5 - blur, 0.5 + blur, fold(
         (lenSq + lenAdd) * (0.8 + 0.5 * cos(timeScale))
       + angle * 2.
       - time
    ));
       
    float spiral2 = smoothstep(0.5 - blur, 0.5 + blur, fold(
         (lenSq + lenAdd) * (1.0 + 0.5 * sin(timeScale))
       - angle * 3.
       - time
    ));

    // Time varying pixel color
    vec3 col = mix(colA, colB, vec3(flXor(spiral1, spiral2)));

    // Output to screen
    glFragColor = vec4(col,1.0);
}

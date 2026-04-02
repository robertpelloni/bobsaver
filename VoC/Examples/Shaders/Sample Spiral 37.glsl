#version 420

// original https://www.shadertoy.com/view/Wl3cDf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float PI = 3.14159265358979;
const mat4x3 colors = mat4x3(
    1.0, 0.7, 0.9,
    1.0, 0.5, 0.6,
    0.3, 0.5, 0.7,
    0.5, 0.6, 0.9
);

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
    float blur = 4.0 / max(0.1, length(uvR));
    float angle = atan(uv.y, uv.x) / PI;
    
    float timeScale = time * PI * 0.125;
    
    float spiral1 = smoothstep(0.5 - blur, 0.5 + blur, fold(
         (lenSq + lenAdd) * 0.8
       + angle * 2.
       - time
    ));
       
    float spiral2 = smoothstep(0.5 - blur, 0.5 + blur, fold(
         (lenSq + lenAdd) * 1.0
       - angle * 3.
       - time
    ));
    vec3 colA = mix(colors[0], colors[1], vec3(flXor(spiral1, spiral2)));

    
    float spiral3 = smoothstep(0.2 - blur, 0.2 + blur, fold(
         (lenSq + lenAdd) * 0.7
       + angle * 5.
       - time
    ));
       
    float spiral4 = smoothstep(0.3 - blur, 0.3 + blur, fold(
         (lenSq + lenAdd) * 1.4
       - angle * 1.
       - time
    ));
    vec3 colB = mix(colors[2], colors[3], vec3(spiral3 * spiral4));
    
    float which = smoothstep(0.5 - blur * 0.5, 0.5 + blur * 0.5, fold(
        lenSq * (1.0 + 0.5 * sin(timeScale))
      - angle
      + time * 0.8
    ));
    
    vec3 col = mix(colA, colB, which);

    // Output to screen
    glFragColor = vec4(col,1.0);
}

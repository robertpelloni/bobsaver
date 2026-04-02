#version 420

// original https://www.shadertoy.com/view/cdVyD1

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define HEX(x) vec3((ivec3(x) >> ivec3(16, 8, 0)) & 255) / 255.

vec3 colormap(float x){
    const int colorCount = 8;
    x *= float(colorCount);
    
    vec3[] c = vec3[](
        HEX(0xff0000),
        HEX(0xff7f00),
        HEX(0xffFF00),
        HEX(0x3fef30),
        HEX(0x00ff00),
        HEX(0x00ffff),
        HEX(0x0000ff),
        HEX(0x8000ff)
    );
    int lo = int(floor(x));
    
    return mix(
        c[lo % colorCount],
        c[(lo + 1) % colorCount],
        fract(x)
    );
}
/*
vec3 colormap(float x) {
    x = fract(floor(x) / 6.) * 3.;
    return mix(
       mix(vec3(1, 1, 0), vec3(0, 1, 1), x),
       mix(vec3(1, 0, 1), vec3(1, 1, 0), x-2.),
       x-1.
    );
}
*/
const float TURN = 2. * acos(-1.);

float squareInSquare(float turn) {
    return sqrt(2.) * cos((mod(turn, 1./4.) - 1./8.) * TURN);
}

float rotation(int layer, float t) {
    if (layer == 0) return 0.125;
    
    return 0.125 + 0.10 * sin(TURN * (
        float(layer) / -22.7
        + t
    ));
}

void main(void)
{
    float t = fract(time / 8.);
    vec2 uv = (2. * gl_FragCoord.xy - resolution.xy) / resolution.y;
    float theta = atan(uv.y, uv.x);

    // Time varying pixel color
    vec4 col = vec4(0);
    
    const int SQUARES = 20; 
    float scale = 1.0;
    float rot = 0.0;
    
    for (int i = 0; i < SQUARES; i++) {
        float lastRot = rot;
        float jRot = rotation(i, t);
        scale *= squareInSquare(jRot);
        rot += jRot;
        
        vec2 angleVec = vec2(
            cos(rot * TURN),
            sin(rot * TURN)
        );
        float df = 16. * max(
            abs(dot(uv, angleVec)),
            abs(dot(uv, vec2(
                angleVec.y, -angleVec.x
            )))
        );
        float v = step(df, scale);
        v *= 1. - col.a;
        col = mix(
            col,
            mix(
                vec4(1),
                vec4(colormap(
                    //+ 0.25 * float((frames >> 0) & 3)
                    + 4. * t
                    + 0.5 * mod(round(
                        4. * (
                        theta / TURN
                        - lastRot
                        )
                    ), 4.)
                    + float(i) / 8.
                ), 1),
                float(0 < i)
            ),
            v
        );
    }

    // Output to screen
    glFragColor = vec4(col.rgb,1.0);
}

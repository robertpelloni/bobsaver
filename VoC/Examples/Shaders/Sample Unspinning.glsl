#version 420

// original https://www.shadertoy.com/view/sdBGRK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-0.5*resolution.xy)/resolution.y;

    uv *= 50.;

    vec2 id = floor(uv);
    vec2 center = id + .5;
    vec2 st = fract(uv);

    float d = 1.;
    const float NNEI = 2.;
    for (float x = -NNEI; x <= NNEI; x++) {
        for (float y = -NNEI; y < NNEI; y++) {
            vec2 ndiff = vec2(x, y);
            vec2 c = center + ndiff;
            float r = length(c);
            float a = atan(c.y, c.x);
            r += sin(time * 5. - r*0.55 - a*2.) * min(r/5., 1.);
            vec2 lc = vec2(r*cos(a), r*sin(a));
            d = min(d, length(uv - lc) + 0.01 * r);
        }
    }
    float w = fwidth(uv.y);
    vec3 col = vec3(smoothstep(0.31+w, 0.31-w, d));

    // Output to screen
    glFragColor = vec4(col,1.0);

}

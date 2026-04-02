#version 420

// original https://www.shadertoy.com/view/7lGGzw

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float thc(float a, float b) {
    return tanh(a * cos(b)) / tanh(a);
}

float ths(float a, float b) {
    return tanh(a * sin(b)) / tanh(a);
}

float mlength(vec2 uv) {
    return max(abs(uv.x), abs(uv.y));
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (gl_FragCoord.xy- 0.5 * resolution.xy)/resolution.y;
    float a = atan(uv.y, uv.x);

    float sc = 24. / (2. + thc(1.5, 8. * mlength(uv) + time));
    float sc2 = -24. / (2. + thc(1.5, 8. * mlength(uv) + time));
    
    float m1 = mix(sc, sc2, .5 + .5 * ths(0.5, 0.3 / length(uv) + 3. * a - time));
    float m2 = mix(sc, sc2, .5 + .5 * ths(0.5, 6. * length(uv) + 3. * a - time));
       
    sc = mix(m1, m2, .5 + .5 * thc(1., 4. * length(uv)+ time));
    
    uv *= 0.55 * sc;
    //vec2 ipos = floor(uv) + 0.5;
    vec2 fpos = fract(uv) - 0.5;

    float l = 0.4 * mlength(fpos);
    float d = 0.1 * min(abs(fpos.x) , abs(fpos.y));
    float s = smoothstep(-l, l,
    0.1 - d + 0.1 * thc(2., 2. * mlength(uv) - 32. * a));
    s *= s;
    vec3 col = vec3(s);

    // Output to screen
    glFragColor = vec4(col,1.0);
}

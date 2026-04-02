#version 420

// original https://www.shadertoy.com/view/wtj3zK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec2 uv = (gl_FragCoord.xy/resolution.xy)-0.5;
    vec2 uv2 = uv;
    vec2 uv3;
    float stalk;
    float petal;
    float center;
    float clouds;
    uv.x *= resolution.x/resolution.y;
    uv *= 5.;
    uv3 = uv;
    
    uv3 -= vec2(0.2, 0.0);
    if(uv2.y < 0.15)
           stalk = 1.- smoothstep(0.80, 1.0, abs((uv3.x + sin(uv3.y * 0.5)) * 20.));
    
    uv -= vec2(-0.2, 0.8);
    float r = cos(atan(uv.y, uv.x) * 7.) * .6 + 0.1;
    petal = smoothstep(r-0.05, r, 1.-length(uv));
    
    center = smoothstep(0.8 - 0.01, 0.8, 1.-length(uv));
    
    vec2 c0 = uv3;
    c0.x += time;
    c0 = mod(c0, vec2(8., 4.)) - vec2(1.8, 1.4);
    
    if(uv2.y > 0.05)
    {
        r = (sin(c0.x * 8.) * 0.8 + 9.);
        c0 *= 5.;
        clouds += 1.-smoothstep(r-0.1, r, length(vec2(c0.x, c0.y * 3.)));
    }

    
    // mix layer together
    vec3 col = vec3(0.0, 0.6, 1.0);
    col = mix(col, vec3(1.0, 1.0, 1.0), clouds);
    col = mix(col, vec3(0.2, 0.6, 0.2), stalk);
    col = mix(col, vec3(1.0, 0.4, 0.4), petal);
    col = mix(col, vec3(1.0, 1.0, 0.4), center);
    
    glFragColor = vec4(col, 1.0);
}

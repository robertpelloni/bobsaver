#version 420

// original https://www.shadertoy.com/view/3tKGWm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.1415

vec2 rotate(vec2 v, float a) {
    float s = sin(a);
    float c = cos(a);
    mat2 m = mat2(c, -s, s, c);
    return m * v;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - 0.5 * resolution.xy)/resolution.y;

    vec3 col = vec3(0);

    vec2 st = rotate(uv, PI * 8. * (-time / 8. + length(uv)));

    float line1 = smoothstep(-0.25, 0.25, st.x);
    float line2 = 1. - line1;
    
    float h = 1.4 * smoothstep(-1., 1., sin(st.x * PI / 2. + 0.75 * PI));
    h -= 1.4 * smoothstep(-1., 1., sin(st.x * PI / 2. + 0.25 * PI));
    
    vec3 c1 = vec3(0.8, 0.2, 0.3);
    vec3 c2 = vec3(0.9, 0.92, 0.96);
    
    // how to create normal normal?
    vec3 normal = normalize(vec3( uv.x, h, uv.y));
    vec3 light = normalize(vec3(0.2 * sin(time/2.), 2.0, 1. * cos(time/2.)));
    float shading = dot(normal, light) * 0.5;
    shading += (1. - length(light.xz - uv) * 2.) * 0.4; 
    float spec = smoothstep(0.46, 1., shading);
    
    col = 1.2 * max(0.2, shading) * (c1 * line1 + c2 * line2);
    col += 2. * smoothstep(0.46, 1., shading);
    col += 0.2 * smoothstep(0.4, 1., shading);
    col += 0.1 * smoothstep(0.3, 1., shading);

    glFragColor = vec4(col,1.0);
}

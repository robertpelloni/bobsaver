#version 420

// original https://www.shadertoy.com/view/DtBXzm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

mat2 rotate2D(float r) {
    return mat2(cos(r), sin(r), -sin(r), cos(r));
}

// based on the follow tweet:
// https://twitter.com/zozuar/status/1621229990267310081
void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    vec3 col = vec3(0);
    float t = time;
    
    vec2 n = vec2(0);
    vec2 q = vec2(0);
    vec2 p = uv + t/4.;
    float S = 10.;
    float a = 0.0;
    mat2 m = rotate2D(1.);

    for (float j = 0.; j < 20.; j++) {
        p *= m;
        n *= m;
        q = p * S + n +.2*sin(t); 
        a += dot(sin(q)/S, vec2(.3));
        n -= cos(q);
        S *= 1.2;
    }

    col = vec3(1, 2, 4) * (3.*a + .3) ;
    
    
    // Output to screen
    glFragColor = vec4(col,1.0);
}

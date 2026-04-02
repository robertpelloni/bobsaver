#version 420

// original https://www.shadertoy.com/view/tlsSzS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Fork of "4-Color Gradient" by unycone. https://shadertoy.com/view/XtXBDs
// 2019-07-18 07:04:37

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;

    // parameters

    vec2 p[4];
    p[0] = vec2(0.1, 0.9);
    p[1] = vec2(0.9, 0.9);
    p[2] = vec2(0.5, 0.1);
    p[3] = vec2(cos(time), sin(time)) * 0.2 + vec2(0.5, 0.5);
    p[2] = vec2(cos(time*0.1), sin(time*0.4)) * 0.2 + vec2(0.5, 0.1);
    p[1] = vec2(0.0, sin(time*0.4)) * 0.2 + vec2(0.9, 0.9);
    p[0] = vec2(cos(time*0.1), sin(time*0.4)) * 0.2 + vec2(0.1, 0.9);
    
    vec3 c[4];
    c[0] = vec3(1.0, 0.0, 0.0);
    c[1] = vec3(0.0, 1.0, 0.0);
    c[2] = vec3(0.0, 0.0, 1.0);
    c[3] = vec3(1.0, 1.0, 0.0);

    float blend = 2.0;
    
    // calc IDW (Inverse Distance Weight) interpolation
    
    float w[4];
    vec3 sum = vec3(0.0);
    float valence = 0.0;
    for (int i = 0; i < 4; i++) {
        float distance = length(uv - p[i]);
        if (distance == 0.0) { distance = 1.0; }
        float w =  1.0 / pow(distance, blend);
        sum += w * c[i];
        valence += w;
    }
    sum /= valence;
    
    // apply gamma 2.2 (Approx. of linear => sRGB conversion. To make perceptually linear gradient)

    sum = pow(sum, vec3(1.0/2.2));
    
    // output
    
    glFragColor = vec4(sum.xyz, 1.0);
}

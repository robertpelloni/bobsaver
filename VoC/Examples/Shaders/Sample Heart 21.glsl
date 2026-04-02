#version 420

// original https://www.shadertoy.com/view/WsdXW7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float pi = 4. * atan(1.);

float phi(float x) {
    float s = sin(pi * x);
    return s*s;
}

void main(void)
{
    vec4 O = glFragColor;
    vec2 U = gl_FragCoord.xy;

    vec2 p = U / resolution.x;
    
    p -= vec2 (0.5, 0.3);
    p *= 8.;
    
    vec2 pm = mouse*resolution.xy.xy / resolution.x;
    
    // heart-shaped polar curve :
    // x = sin^3(t)
    // y = cos(t) - cos^4(t)

    float sc = 2.;
    int nb_pts = 50;
    float dt = 2. * pi / float (nb_pts);
    
    O = vec4(0.);
    
    for (int k=0; k < nb_pts; k++) {
        float t = sc * (time + float(k) * dt);
        float c = cos(t), s = sin(t);
        vec2 m = (1. + phi(0.7 * time) / 2.) * vec2(1.5 * s*s*s, 0.5 + c - c*c*c*c);
        float e = smoothstep (.1, .0, length(p-m));

        // blending between red and blue suggests that
        // blood's color depends on whether it enters or
        // exits the heart.
        
        O += vec4(mix (vec3(e, 0., 0.), vec3(0., 0., e), (1. + s) / 2.), 1.);
    }

    glFragColor = O;
}

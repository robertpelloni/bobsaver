#version 420

// original https://www.shadertoy.com/view/Ml3SRs

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// This is probably way too many layers/flakes for full-screen. Play around with them
#define _NUMSHEETS 10.
#define _NUMFLAKES 400.

vec2 uv;

// The classic GLSL random function
float rnd(float x)
{
    return fract(sin(dot(vec2(x+47.49,38.2467/(x+2.3)), vec2(12.9898, 78.233)))* (43758.5453));
}

// From https://www.shadertoy.com/view/MscXD7
float drawFlake(vec2 center, float radius)
{
    return 1.0 - sqrt(smoothstep(0.0, radius, length(uv - center)));
}

void main(void)
{
    uv = gl_FragCoord.xy / resolution.x;
    //vec3 col = vec3(0.63, .85, .95);
    vec3 col = vec3(0.0,0.05,0.1);
    for (float i = 1.; i <= _NUMSHEETS; i++){
        for (float j = 1.; j <= _NUMFLAKES; j++){
            // We want fewer flakes as they get larger
            if (j > _NUMFLAKES/i) break;
            
            // Later sheets should have, on average, larger and faster flakes
            // (to emulate parallax scrolling)
            float size = 0.002 * i * (1. + rnd(j)/2.);            
            float speed = size * .75 + rnd(i) / 1.5;
            
            // The two terms randomize the x pos and spread it out enough that we don't
            // Get weird hard lines where no snow passes.
            // The last term gives us some side-to-side wobble
            vec2 center = vec2(0., 0.);
            center.x = -.3 + rnd(j*i) * 1.4 + 0.1*cos(time+sin(j*i));
            center.y = fract(sin(j) - speed * time) / 1.3;
            
            // As the sheets get larger/faster/closer, we fade them more.
            col += vec3( (1. - i/_NUMSHEETS) * drawFlake(center, size));
        }
    }
    glFragColor = vec4(col,1.0);
}

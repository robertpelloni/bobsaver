#version 420

// original https://www.shadertoy.com/view/3lcSWn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Trying to replicate this effect:
// https://twitter.com/Rainmaker1973/status/1223984952255176704

float rectangle(vec2 uv, vec2 pos, vec2 size)
{
    size *= 0.5;
    vec2 r = abs(uv - pos - size) - size;
    
    return step(max(r.x,r.y), .0);
}

mat2 rotate(float angle)
{
    float s = sin(angle);
    float c = cos(angle);

    return mat2(c, -s, s, c);
}

void main(void)
{
    vec2 uv = (2.*gl_FragCoord.xy-resolution.xy) / resolution.y * .5;
    uv *= rotate(time*.1);
    
    vec3 c = vec3(0);
    float y = sin(time*3.)*.05;
    float x = cos(time*3.)*.05;

    float lines = rectangle(uv, vec2(-.15, .2+y), vec2(.3,.01));
    lines += rectangle(uv, vec2(-.15, -.2+y), vec2(.3,.01));
    lines += rectangle(uv, vec2(-.2+x, -.15), vec2(.01,.3));
    lines += rectangle(uv, vec2(.19+x, -.15), vec2(.01,.3));
    
    float occluders = rectangle(uv, vec2(-.3, .1), vec2(.2,.2));
    occluders += rectangle(uv, vec2(.1, .1), vec2(.2,.2));
    occluders += rectangle(uv, vec2(-.3, -.3), vec2(.2,.2));
    occluders += rectangle(uv, vec2(.1, -.3), vec2(.2,.2));

    occluders = abs(sin(occluders*time*.2)*1.3);
    c += lines + occluders;

    glFragColor = vec4(vec3(c), 1.);
}

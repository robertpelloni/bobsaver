#version 420

// original https://www.shadertoy.com/view/Wtf3zl

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv-=.5;
    uv.x*= resolution.x/resolution.y;
    
    vec3 col = vec3(0.);
    float d = length(uv)*20.;
    float a = atan(uv.y, uv.x);
    col.r = smoothstep(0.1, .2, abs(mod(d+time, 2.)-1.));
    col.g = col.r*floor(mod(d*.5+.5+time*.5, 2.));
    float f = smoothstep(-.1, .1,sin(a*3.+(sin(time*.5)*2.)*d-time));
    col.rg = mix(col.rg, 1.-col.rg, f);

    // Output to screen
    glFragColor = vec4(col,1.0);
}

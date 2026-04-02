#version 420

// original https://www.shadertoy.com/view/XdyfWt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec4 color( in vec2 gl_FragCoord, in vec2 centerCoord )
{

    float dist = length(centerCoord - gl_FragCoord);
    
    // Time varying pixel color
    vec3 col = 0.5 + 0.5*cos(vec3(dist/10.0) - time * vec3(11.0,3.0,7.0) );

    float cutoff = 40.0;
    float d = min(1.0, max(cutoff/dist, .3));
    return vec4(col*d, 1.0);
}

void main(void)
{
    glFragColor  =
        color(gl_FragCoord.xy, resolution.xy/2.0 + 30.0 * vec2(sin(time), cos(time)))
        -color(gl_FragCoord.xy, mouse*resolution.xy.xy);
}


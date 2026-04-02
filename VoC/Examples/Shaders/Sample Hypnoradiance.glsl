#version 420

// original https://www.shadertoy.com/view/MdtBRj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.1415926535897932384626433832795

void main(void)
{
    int rayCount = 12;
    vec3 color1 = vec3(1.,1.,0.);
    vec3 color2 = vec3(.8,0.45,.65);
    
    // center
    vec2 c = (gl_FragCoord.xy - vec2(resolution) * .5) / resolution.y;
    
    // cartesian to polar
    float angle = atan(c.y, c.x);
    float dist = length(c);
    
    // normalize angle
    angle /= (2.*PI);
    
    // wave
    float time = mod(time * 5., 2.*PI);
    angle += (1. + sin(dist*40. - time)) * (1.-dist) * .01;
    
    // fraction angle
    float mask = fract(angle * float(rayCount));
    
    // smooth fract output
    mask = min(1. - mask, mask) * 2.;
    mask = smoothstep(.4, .6, mask);
    
    // radial gradient
    mask -= dist;
    
    // output
    glFragColor = vec4(mix(color2, color1, mask),1.0);
}

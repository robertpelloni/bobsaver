#version 420

// original https://www.shadertoy.com/view/XlsfzH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define rot(a) mat2(cos(a), -sin(a), sin(a), cos(a)) // col1a col1b col2a col2b
const float gridWidth = .33;

vec3 hue( float c ){
    return smoothstep(0.,1., abs(mod(c*6.+vec3(0,4,2), 6.)-3.)-1.);
}

void main(void)
{
    vec2 uv = (2. * gl_FragCoord.xy - resolution.xy) / resolution.y;
    float threshold = .03;
    vec2 node = round(uv / gridWidth) * gridWidth;
    
    float sizeNum = sin((-time * 1.5  + pow(length(node), 3.2)) * 1.5) * 1.3;
    vec2 to = uv - node;
    to /= abs(sizeNum) + .4;
    to *= rot(sin(time * 15.) * .15);
    float d = length(max(abs(to) - .050, 0.));
    
    vec3 col = .5+.5*hue(sizeNum / 3.);
    
    float val = smoothstep(threshold + .01, threshold, d);
    glFragColor.rgb = mix( vec3(0,.5,.5), col, val);
}

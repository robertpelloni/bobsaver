// https://www.shadertoy.com/view/llXGWf

#version 400

uniform vec2 resolution;
uniform sampler2D image;

out vec4 glFragColor;

// by Nikos Papadopoulos, 4rknova / 2015
// WTFPL

// Sharpness kernel
// -1 -1 -1
// -1  9 -1
// -1 -1 -1

vec3 texsample(const int x, const int y, in vec2 fragCoord)
{
    vec2 uv = fragCoord.xy / resolution.xy * resolution.xy;
	uv = (uv + vec2(x, y)) / resolution.xy;
	return texture(image, uv).xyz;
}

vec3 texfilter(in vec2 fragCoord)
{
    vec3 sum = texsample(-1, -1, fragCoord) * -1.
             + texsample(-1,  0, fragCoord) * -1.
             + texsample(-1,  1, fragCoord) * -1.
             + texsample( 0, -1, fragCoord) * -1.
             + texsample( 0,  0, fragCoord) *  9.
             + texsample( 0,  1, fragCoord) * -1.
             + texsample( 1, -1, fragCoord) * -1.
             + texsample( 1,  0, fragCoord) * -1.
             + texsample( 1,  1, fragCoord) * -1.;
    
	return sum;
}

void main()
{
    float u = gl_FragCoord.x / resolution.x;
    float m = 0;//iMouse.x / iResolution.x;
    
    float l = smoothstep(0., 1. / resolution.y, abs(m - u));
    
    vec2 fc = gl_FragCoord.xy;
    //fc.y = resolution.y - gl_FragCoord.y;
    
    vec3 cf = texfilter(fc);
    vec3 cl = texsample(0, 0, fc);
    vec3 cr = (u < m ? cl : cf) * l;
    
    glFragColor = vec4(cr, 1);
}
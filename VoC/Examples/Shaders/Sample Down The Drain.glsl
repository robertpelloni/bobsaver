#version 420

// original https://www.shadertoy.com/view/3dt3zr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float PI = 3.1415926535897932384626433832795;

//from https://www.shadertoy.com/view/MsS3Wc
vec3 hsb2rgb( in vec3 c ){
    vec3 rgb = clamp(abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),
                             6.0)-3.0)-1.0,
                     0.0,
                     1.0 );
    rgb = rgb*rgb*(3.0-2.0*rgb);
    return c.z * mix(vec3(1.0), rgb, c.y);
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy - .5;
    uv.y *= resolution.y / resolution.x;
    
    
    vec2 polarized = vec2((atan(uv.y, uv.x)+PI)/(2.0*PI), length(uv));

    vec3 col = vec3(polarized, 0);
    
    col = hsb2rgb(vec3(polarized.y+sin(polarized.x*20.0*PI + sin(time*5.0)*20.0*polarized.y)*.2*polarized.y + time, polarized.y*2.0, 1.0-polarized.y));

    // Output to screen
    glFragColor = vec4(col,1.0);
}

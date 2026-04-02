#version 420

// original https://www.shadertoy.com/view/3ljcWt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define TWO_PI 6.28318530718

//  Function from Iigo Quiles
//  https://www.shadertoy.com/view/MsS3Wc
vec3 hsb2rgb( in vec3 c ){
    vec3 rgb = clamp(abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),
                             6.0)-3.0)-1.0,
                     0.0,
                     1.0 );
    rgb = rgb*rgb*(3.0-2.0*rgb);
    return c.z * mix( vec3(1.0), rgb, c.y);
}

void main(void) {
    vec2 st = gl_FragCoord.xy/resolution.xy;
    vec3 color = vec3(0.0);

    // Use polar coordinates instead of cartesian
    vec2 toCenter = vec2(0.5)-st;
    float angle = atan(toCenter.y,toCenter.x) + time * TWO_PI;
    float radius = length(toCenter)*2.5;

    // Map the angle (-PI to PI) to the Hue (from 0 to 1)
    // and the Saturation to the radius
    color = hsb2rgb(vec3((angle/TWO_PI)+0.5,radius,1.0));

    float dis = length(gl_FragCoord.xy - 0.5 * resolution.xy);
    float shortestRes = min(resolution.x, resolution.y);
    float ring = step(0.15 * shortestRes, dis) - step(0.45 * shortestRes, dis);
    color = mix(vec3(0.0), color, ring);

    glFragColor = vec4(color,1.0);
}

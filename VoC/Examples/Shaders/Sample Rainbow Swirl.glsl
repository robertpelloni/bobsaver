#version 420

// original https://www.shadertoy.com/view/3s3Gzn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define t .005 // thickness as % of screen

// Smooth HSV to RGB conversion 
// as made by iq himself
vec3 hsv2rgb_smooth( in vec3 c )
{
    vec3 rgb = clamp( abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),6.0)-3.0)-1.0, 0.0, 1.0 );

    rgb = rgb*rgb*(3.0-2.0*rgb); // cubic smoothing    

    return c.z * mix( vec3(1.0), rgb, c.y);
}

float clampSinTime(float x)
{
    return (sin(time + x) + 1.) / 2.;
}

vec3 rainbow(vec2 uv, float curve)
{
    float div = step(curve, uv.x) * 2.;
    float time = -(time - time * div) * 2.;
    time *= 0.1;
    
    float hue = 2. * (uv.x - curve - time);
    
    if (uv.x > curve) hue = -hue;
    
    return vec3(hue, 1., 1.);
}

vec3 drawLine(vec2 uv, vec3 col, float curve)
{
    float dist = 1.025 - 3.5 * abs(curve - uv.x);
    col.y -= dist;
    //col += vec3(step(curve, limit + t) * step(limit - t, curve));
    return col;
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    
    float waviness = sin(time) * 1.25;
    float vertSinCurve = (clampSinTime(uv.y * 7.5) * .1) * waviness + .5;
    
    vec3 l = rainbow(uv, vertSinCurve);
    
    l = drawLine(uv, l, vertSinCurve);
    l = hsv2rgb_smooth(l);
   
    // Output to screen
    glFragColor = vec4(l, 1.);
}

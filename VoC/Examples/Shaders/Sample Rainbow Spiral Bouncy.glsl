#version 420

// original https://www.shadertoy.com/view/flsXDs

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 hsl2rgb( in vec3 c )
{
    vec3 rgb = clamp( abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),6.0)-3.0)-1.0, 0.0, 1.0 );
    return c.z + c.y * (rgb-0.5)*(1.0-abs(2.0*c.z-1.0));
}

void main(void)
{
    vec2 st = gl_FragCoord.xy/vec2(resolution.y, resolution.y);
    vec2 m = vec2(abs(sin(time /4.))* resolution.x, abs(cos(time *.95)) * resolution.y)/vec2(resolution.y, resolution.y);
    vec2 v = st - m;
    v = v / 0.01;
    float tau = 6.283185;
    float hue = atan(v.x, v.y)/tau;
    hue = hue + length(v)/80. - time/2.;
    vec3 rgb = hsl2rgb ( vec3(hue, 1., 
                              cos(2.0-length(v)*3.5)));
    glFragColor = vec4(rgb.r,rgb.g,rgb.b,1.0);
}

#version 420

// original https://www.shadertoy.com/view/4lVXzc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 hsv(float h, float s, float v)
{
  return mix( vec3( 1.0 ), clamp( ( abs( fract(
    h + vec3( 3.0, 2.0, 1.0 ) / 3.0 ) * 6.0 - 3.0 ) - 1.0 ), 0.0, 1.0 ), s ) * v;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy / resolution.xy)*2.+-1.;
    uv.x *= resolution.x/resolution.y;
    vec2 z = uv;
    float t=0.0;
    for (int i = 0; i < 5; i++)
    {
        z = vec2(z.x * z.x - z.y * z.y, 2.*z.x*z.y)-vec2(sin(time), cos(time));
        if (t< 5.) t = distance(z, vec2(0.));
        if (t >= 5.) t = pow(dot(z,z), float(i)/t);
        
    }
    glFragColor = vec4(hsv(t + time, 1., 1.),1.0);
}

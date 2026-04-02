#version 420

// original https://www.shadertoy.com/view/wtGfWc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float r = 0.355;
const float i = 0.355;

vec2 Complex_sqr( vec2 z )
{
    return vec2( z.x * z.x - z.y * z.y, 2.0 * z.x * z.y);
}

float getNorm ( vec2 z )
{
    return sqrt(dot(z, z));
}

float GetColor( float t, vec2 pixels )
{
    vec2 c = vec2(r, cos(t) * i);
    vec2 z = pixels;
    float iterations = 0.0;
    while ( getNorm(z) < 20.0 && iterations < 300.0 )
    {
        z = Complex_sqr(z) + c;
        iterations += 1.0;
    }
    return 1.0 - iterations * 0.004; 
}

void main(void)
{
    float aspectRatio = resolution.x / resolution.y;
    vec2 pixel = vec2((gl_FragCoord.xy/resolution.xy) * 2.0 - 1.0) * 1.2;
    pixel.x *= aspectRatio;
    float color = GetColor(time, pixel);
    // Output to screen
    glFragColor = vec4(color, color, color, 1.0);
}

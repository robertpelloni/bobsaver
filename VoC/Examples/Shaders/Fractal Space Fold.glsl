#version 420

// original https://www.shadertoy.com/view/lsGSzW

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float tau = 8.0 * atan(1.0);

mat2 rot(float angle) {
    return mat2(cos(angle), -sin(angle),
                sin(angle), cos(angle));
}

// http://iquilezles.org/www/articles/palettes/palettes.htm
vec3 palette( in float t )
{
    vec3 a = vec3(0.5);
    vec3 b= vec3(0.5);
    vec3 c= vec3(1.0, 1.0, 0.5);
    vec3 d= vec3(0.8, 0.9, 0.3);
    return a + b*cos( 6.28318*(c*t+d) );
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy * 2.0 - 1.0;
    uv.x *= resolution.x / resolution.y;
    for(int i = 0; i < 32; i++) {
        uv = abs(uv);
        uv *= rot(time/30.0);
        uv += -vec2(0.5,0.5);
        uv *= 1.03;
    }
    uv = pow(abs(sin(uv)),vec2(0.3));
    vec3 col = palette(uv.x*uv.y*1.9);
    glFragColor = vec4(col,1.0);
}

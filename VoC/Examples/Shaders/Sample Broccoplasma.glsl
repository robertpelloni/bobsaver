#version 420

// original https://www.shadertoy.com/view/WtKSWh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define ROT (time/50.0)

const float tau = atan(1.0)*8.0;

// http://iquilezles.org/www/articles/palettes/palettes.htm
// cosine based palette, 4 vec3 params
vec3 palette( in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d )
{
    return a + b*cos( 6.28318*(c*t+d) );
}

vec3 color(float t) {
    t = mod(t, 1.0);
    return palette(t, vec3(0.5), vec3(0.5), vec3(1.0, 0.7, 0.4), vec3(0.00, 0.15, 0.20));
}

void main(void)
{
    // Normalized pixel coordinates (from -1 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy * 2.0 - 1.0;

    uv.x += time/100.0;
    
    vec3 col = vec3(sin(uv.x) + sin(uv.y));
    for(int i=0; i<6; i++) {
        float fi = float(i);
        uv *= 3.0;
        uv *= mat2(cos(fi*ROT), -sin(fi*ROT), sin(fi*ROT), cos(fi*ROT));
        col += (distance(sin(uv.x + cos(uv.y*10.0)/10.0 + time),cos(uv.y + cos(uv.x*10.0)/10.0)))/
                pow(1.85, fi);
    }
    col += 0.8;
    col *= col;
    col = color(col.x/35.0);

    // Output to screen
    glFragColor = vec4(col,1.0);
}

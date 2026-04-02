#version 420

// original https://www.shadertoy.com/view/wtXyDf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 cube_round(vec3 cube)
{
    float rx = round(cube.x);
    float ry = round(cube.y);
    float rz = round(cube.z);

    float x_diff = abs(rx - cube.x);
    float y_diff = abs(ry - cube.y);
    float z_diff = abs(rz - cube.z);

    if (x_diff > y_diff && x_diff > z_diff) {
        rx = -ry - rz;
    } else if (y_diff > z_diff) {
        ry = -rx - rz;
    } else {
        rz = -rx - ry;
    }

    return vec3(rx, ry, rz);
}

vec2 cube_to_axial(vec3 cube)
{
    float q = cube.x;
    float r = cube.z;
    return vec2(q, r);
}

vec3 axial_to_cube(vec2 hex)
{
    float x = hex.x;
    float z = hex.y;
    float y = -x - z;
    return vec3(x, y, z);
}

vec2 hex_round(vec2 hex)
{
    return cube_to_axial(cube_round(axial_to_cube(hex)));
}

const float size = 20.0;

vec2 pixel_to_pointy_hex(vec2 point)
{
    float q = (sqrt(3.0) / 3.0 * point.x - 1.0 / 3.0 * point.y) / size;
    float r = (2.0 / 3.0 * point.y) / size;
    return hex_round(vec2(q, r));
}

vec2 pointy_hex_to_pixel(vec2 hex)
{
    float x = size * (sqrt(3.0) * hex.x  +  sqrt(3.0) / 2.0 * hex.y);
    float y = size * (3.0 / 2.0 * hex.y);
    return vec2(x, y);
}

vec2 opModPolarMirrored( in vec2 p, float theta, float offset)
{
    float a = atan(p.y, p.x) - offset;
    a = abs(mod(a + .5 * theta, theta) - .5 * theta);
    return length(p) * vec2(cos(a), sin(a));
}

float rand(vec2 co)
{
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

mat2 rotate(float a)
{
    float c = cos(a);
    float s = sin(a);
    return mat2(c, -s, s, c);
}

void main(void)
{
    float scale = 150.;
    scale = 500. + 450. * cos(radians(1.) * time + radians(90.));

    vec2 uv = scale * (gl_FragCoord.xy - .5 * resolution.xy) / resolution.y;
    uv = rotate(radians(2.) * time + radians(10.)) * uv;
    
    vec2 hex = pixel_to_pointy_hex(uv);
    vec2 uv2 = pointy_hex_to_pixel(hex);

    float b = smoothstep(-.1, .1, sin(radians(360.) * rand(floor(hex)) + radians(20.) * time));
    
    vec2 rel = opModPolarMirrored(uv2 - uv, radians(360.) / 3., radians(30. + 60. * b));
    float r = abs(length(rel - vec2(size, 0.)) - 10.) - 2.;
    
    float d = smoothstep(0., 2. * scale / resolution.y, r);
    vec3 col = vec3(d);

    uv = gl_FragCoord.xy / resolution.xy;
    col *= pow( 16.0*uv.x*(1.0-uv.x)*uv.y*(1.0-uv.y), 0.18 );
      glFragColor = vec4(col, 1);
}

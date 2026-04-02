#version 420

// original https://www.shadertoy.com/view/DlVyzV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define TAU 6.28318530718
#define PI 3.14159265359

mat2 rot2D(float angle) {
    // angle *= PI / 180.0;
    float s = sin(angle), c = cos(angle);
    return mat2( c, -s, 
                 s,  c);
}

float grid(vec2 uv, vec2 scale) {
    uv = sin(PI * uv * scale); 
    float v = uv.x * uv.y;
    return smoothstep(1.,-1., v/fwidth(v));
}

vec3 spherical(vec2 uv, float r) {
    float theta = -PI + TAU * uv.x;
    float phi = mix(uv.y, -PI, PI);
    float sp = sin(phi);
    return vec3(
        r * cos(theta) * sp,
        r * sin(theta) * sp,
        r * cos(phi)
    );
}

vec2 mercator(vec3 xyz, float r) {
    float lat = asin(xyz.z);
    float lon = atan(xyz.y, xyz.x);
    
    return vec2(
        r * lon,
        r * log(tan(PI/4. + lat/2.))
    );
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    vec2 grid_size = resolution.xy / 256.;

    vec3 xyz = spherical(uv, 1.);   
    xyz.yz *= rot2D(0.5 * time);
    xyz.xz *= rot2D(0.5 * time);

    vec2 uv2 = mercator(xyz, 1.);

    // grid
    float c = grid(uv2, grid_size);

    // Output to screen
    glFragColor = vec4(c, c, c, 1.0);
}

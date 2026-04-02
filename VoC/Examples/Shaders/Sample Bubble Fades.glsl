#version 420

// original https://www.shadertoy.com/view/3tfGD7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159265359

mat2 rot(float a) { return mat2(cos(a), -sin(a), sin(a), cos(a)); }

float circle(vec2 uv) {
    return sqrt(dot(uv, uv));
}

void main(void)
{
    // ** UV
    vec2 uv = ((gl_FragCoord.xy-.5*resolution.xy)/resolution.y); // Normalized pixel coordinates (from 0 to 1)
    uv = uv * rot(time*0.1); // Normalized rotating uv
    
    // Rotation matrix
    float n = 6.+abs(sin(time*0.1)*2.); // Grid size
    
    // Cell ID
    vec2 idv2 = (floor(uv*n) + vec2(n,0));;
    float id = idv2.x*n + idv2.y;
    
    // ** Grids
    vec2 guv = fract(uv*n) -.5; // Grid uv
    vec2 roguv = guv; roguv *= rot(time); // Rotating grid uv - around self origin

    // Circle uv
    float r1 = 0.45 * sin(dot(idv2, idv2) + time)*sin(id*0.5), r2 = 0.5;
    vec2 croguv = roguv * (1.-smoothstep(r1,r2, circle(roguv)));
    
    // Final color
    vec3 fc = dot(croguv,croguv)/0.25*vec3(1.);
    vec3 col = fc;

    // Output to screen
    glFragColor = vec4(col,1.0);
}

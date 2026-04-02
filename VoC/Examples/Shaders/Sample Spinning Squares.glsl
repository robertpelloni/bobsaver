#version 420

// original https://www.shadertoy.com/view/3sXfzj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.1415

float line(vec2 uv, float m, float b)
{
    float y = m*uv.x+b;
    return smoothstep(y + 0.01, y, uv.y) - smoothstep(y, y - 0.01, uv.y);
}

vec2 rotate2d(vec2 uv, float angle)
{
    uv -= 0.5;
     uv *= mat2(cos(angle), sin(angle),
               -sin(angle), cos(angle));  
    
    uv += 0.5;
    return uv;
}

float random (in vec2 st) {
    return fract(sin(dot(st.xy,
                         vec2(12.9898,78.233)))*
        43758.5453123);
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv.x *= resolution.x/resolution.y;
    vec3 col = vec3(0.0);
    
    uv *= 2.25;
    float evenAngle = 0.0;
    float m1  = mod(floor(uv.x), 2.0);
    float m2  = mod(floor(time), 2.0);
    float res = m1 == m2 ?  1.0 : -1.0;
    
    if (sin(time * PI * .25 ) > 0.0)
    {
        uv.y = fract(uv.y + time * res * m2);
        uv = rotate2d(fract(uv), m2 * PI * time * .5);
    }
    else
    {
        uv = rotate2d(fract(uv), m2 * PI * time * .5);
    }
    
    //
    float l = (1.0 - length(floor(uv)));
    col +=  line(fract(uv),  1.0, -0.5) * l;
    col +=  line(fract(uv), -1.0,  0.5) * l;
    col +=  line(fract(uv),  1.0,  0.5) * l;
    col +=  line(fract(uv), -1.0,  1.5) * l;
    
    // Output to screen
    glFragColor = vec4(col,1.0);
}

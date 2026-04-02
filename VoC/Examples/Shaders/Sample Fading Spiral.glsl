#version 420

// original https://www.shadertoy.com/view/Wt2fRw

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Spiral function is taken from https://www.shadertoy.com/view/ldBGDc
float spiral(vec2 m) {
    float r = length(m);
    float a = atan(m.y, m.x);
    float v = sin(50.*(sqrt(r) - 0.02 * a - .2 * time));
    return clamp(v,0.,1.);
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv -= 0.5;
    uv.x *= resolution.x/resolution.y;
    
    float sp = spiral(uv);
    float sig = sign(uv.x);
    uv.x -= sig * sp;

    float d = length(uv);
    float res = 1.0 - d;
    
    vec3 color = vec3(res);
    glFragColor = vec4(color,1.0);
}

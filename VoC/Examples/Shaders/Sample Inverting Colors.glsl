#version 420

// original https://www.shadertoy.com/view/WlsyDr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float PI = 3.141592;

float circ(vec2 pos, vec2 midpoint) {
    return step(0.4, length(pos - midpoint));
}

float sdEquilateralTriangle( in vec2 p )
{
    const float k = sqrt(3.0);
    
    p.x = abs(p.x) - 1.0;
    p.y = p.y + 1.0/k;
    if( p.x + k*p.y > 0.0 ) p = vec2( p.x - k*p.y, -k*p.x - p.y )/2.0;
    p.x -= clamp( p.x, -2.0, 0.0 );
    return step(-length(p)*sign(p.y), mod(time/5., 2.));
}

void main(void)
{    
    float w = 0.2;
    
    // Normalized pixel coordinates (from 0 to 1)
    vec2 pos = gl_FragCoord.xy/resolution.xy * 2. - 1.;
    pos.x *= resolution.x/resolution.y;

    vec3 color = vec3(step(w/2., mod(pos.x + pos.y,w)));
    // Smoothstep attempt, still too blurry at edges
    color = vec3(smoothstep(3.*w/8., 5.*w/8., mod(pos.x + pos.y,w)));
    
    float c1 = circ(pos, vec2(mod(time/2.,4.)*2. - 4., 0.4));
    
    float c2 = circ(pos, vec2(0.2,mod(time/2.,4.)*2. - 4.));
    
    float c3 = circ(pos, vec2(sin(time/3.)*2.,sin(time/3. * 3.) * 3.));
    
    float invert = mod(c1 + c2 + c3 + sdEquilateralTriangle(pos), 2.);
    
    color =  invert * color + (1. - invert) * (1. - color);
    
    // Output to screen
    glFragColor = vec4(color,1.0);

}

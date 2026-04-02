#version 420

// original https://www.shadertoy.com/view/Wll3Wl

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float circle(vec2 pos, float radius){
    float dx = 1./resolution.y;
    return clamp(.5*(radius - length(pos)+dx) / dx, 0., 1.);
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy - 0.5;
    vec2 u = uv;
    u.x*=resolution.x/resolution.y;
    float k = 1.;
    for(float i = 1.; i < 40.; i++){
        float a = .1*i*time;
        u += vec2(sin(a),cos(a))*.05;
        k += circle(u, 2.0 - 0.05*i);
    } 
    glFragColor = vec4(1.-abs(1.-mod( k, 2.)));
}

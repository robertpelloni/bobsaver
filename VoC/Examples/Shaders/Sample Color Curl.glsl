#version 420

// original https://www.shadertoy.com/view/WltfDH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159265358979323846

float spiral(vec2 uv, float rep, float twist, float phase, float angV){
    angV  *= time * PI * rep;
    phase += angV;
    
    float ang = atan(uv.y, uv.x) / 2. * rep + phase;
    float len = length(uv) * twist;
    float off = len + ang / PI;
    
    return mod(off, 1.);
}

void main(void)
{
    vec2 uv    =  gl_FragCoord.xy / resolution.xy;
    vec2 pos   =  uv * 2.;
         pos   -= 1.;
         pos.x *= resolution.x / resolution.y;
    
    float sp1 = spiral(pos, 1., sin(time / 2.0) *  3., 0., 1.0);
    float sp2 = spiral(pos, 1., sin(time / 2.1) * -5., 0., -2.);
    float sp3 = spiral(pos, 1., sin(time / 2.2) *  4., 0., 2.7);
    
    vec3 col = vec3(sp1, sp2, sp3);
    
    glFragColor = vec4(col, 1.);
}

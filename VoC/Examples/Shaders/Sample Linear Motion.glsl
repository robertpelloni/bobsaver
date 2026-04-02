#version 420

// original https://www.shadertoy.com/view/4lKyzd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Every dot is moving only on a line, there is no circular motion.

#define POW2(A) ((A)*(A))

#define R resolution

vec2 dot_pos(float r, float t){
    return (POW2(sin(t-r*9.42))+.2)*cos(r*6.28-vec2(0,33));
}

float draw_dot(vec2 uv, float r, float t){
    return smoothstep(10./R.y,.0,length(uv-dot_pos(r,t)) - .022);
}

// Rainbow color mapping from angle r in [0,1]
vec3 dot_color(float r){
    float a=(1.-r)*6.;
    return clamp(vec3(abs(a-3.)-1., 2.-abs(a-2.), 2.-abs(a-4.)),
                 0.,1.);
}

void main(void)
{
    vec2 uv = 1.3*(2.*gl_FragCoord.xy-R.xy)/R.y;
    vec3 col = vec3(0);
    
    float t = time*2.;
    
    float r = round(fract(atan(uv.y,uv.x)/6.28) * 16.)/16.;
    vec3 c = dot_color(r);
    col += c * min(1.,draw_dot(uv,r,t)
                      // Motion blur
                      + .5 * draw_dot(uv,r,t-.04)
                      + .2 * draw_dot(uv,r,t-.08));
    
    glFragColor = vec4(col,1);
}

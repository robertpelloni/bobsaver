#version 420

// original https://www.shadertoy.com/view/7sGcz1

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// color palettes from 'Palettes' by iq

//filtered cosine also courtesy of iq ('Bandlimited Synthesis 2')

#define FLTR
vec3 fcos( vec3 x )

{
    #ifdef FLTR
    vec3 w = fwidth(x);   
    return cos(x) * sin(0.5*w)/(0.5*w);
    #else
    return cos(x);
    #endif
}

vec3 pal( in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d )
{
    return a + b*fcos( 6.28318*(c*t+d) );
}
void main(void)
{
    vec2 uv = vec2(-.745,.186) + 3.*(gl_FragCoord.xy/resolution.y-.5)*pow(.01,1.+cos(.2*(time+22.)));
    vec2 z = vec2(0.0);
    float dmin_dt = 100000.0;
    float dmin_ln = 100000.0;
    for (int i = 0; i < 256; i++) {
        z = uv + vec2((z.x * z.x) - (z.y * z.y), 2.0 * z.x * z.y);
        dmin_dt = min(dmin_dt, length(z));
        dmin_ln = min(dmin_ln,
            min(abs(z.x + 4.0 * sin(0.5 * z.x)), abs(z.y + 4.0 * cos(0.5 * z.x))));    
    }
    vec3 col_ln = pal( dmin_dt * 4.0 ,
        vec3(0.5,0.5,0.5),
        vec3(0.5,0.5,0.5),
        vec3(1.0,1.0,1.0),
        vec3(0.0,0.10,0.20) );
    vec3 col_dt = pal( dmin_ln * 8.0,
        vec3(0.5,0.5,0.5),
        vec3(0.5,0.5,0.5),
        vec3(1.0,1.0,0.5),
        vec3(0.8,0.90,0.30) );
    glFragColor = vec4((col_ln + col_dt) * 0.50, 1.0);
}

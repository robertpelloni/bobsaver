#version 420

// original https://www.shadertoy.com/view/3sGBzm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float Random(vec2 p) {
    p = fract(p*vec2(123.34, 456.21));
    p += dot(p, p+45.32);
    return fract(p.x*p.y);
}

float T(float a) {
    float random = Random(vec2(a*532.43, a*784.34));
    float interval = clamp(random, 0.3, 0.6);
    return clamp((sin(time*a*1.4*random)+1.)/2., 0., 1.);
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    vec3 col = vec3(0.);
    
    // scaling
    uv.x *= 4.5;
    uv.y -= .5;
    
    // bars
    for(float i=.0; i<64.; i=i+2.){
        // thickness
        float width = 0.10*(sin(time*Random(vec2(i, 654.543)))*.5+.6);
        float edge = 0.3*(sin(time*Random(vec2(i, 654.543)))*.5+.6);
        
        //bar
        float m1 = smoothstep(width+edge, width, abs((uv.x-3.2+(i/10.))));
        col += m1 * T(2.+(i*.02));
    }
    
    // colors
    col.r -= T(4.);
    col.g -= T(5.);
    col.b -= T(6.);
    
    // vignette
    col *= smoothstep(-.95, .0, uv.y);
    col *= smoothstep(0., -.95, uv.y);
    col *= smoothstep(-5., 1., uv.x);
    col *= smoothstep(5., -1., uv.x);
    col += col*2.;
    
    glFragColor = vec4(col,1.0);
}

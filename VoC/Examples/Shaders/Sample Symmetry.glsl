#version 420

// original https://www.shadertoy.com/view/wdVfzG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

mat2 Rot(float a) {
    float s=sin(a), c=cos(a);
    return mat2(c, -s, s, c);
}

float Hash21(vec2 p) {
    p = fract(p*vec2(123.34, 456.21));
    p += dot (p, p+45.32);
    return fract(p.x*p.y);
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    float aa = 1.5 / resolution.y;
    vec3 col = vec3(0.);
    uv *= 1.4;
    //uv *= Rot(time*.1);
    
    uv.x = abs(uv.x) -.1;
    uv.y = abs(uv.y) -.1;
            
    float str = .11;
    float sz = .2;
    float w = 0.0;
 
    col += smoothstep(.1+aa, .1, length(uv.x)+length(uv.y))*str;
    
    uv *= Rot(cos(time*.1)*3.1415);
    
    col += smoothstep(sz, sz+aa, length(uv.x-.1-w)+length(uv.y-.1))*str;
    col += smoothstep(sz, sz+aa, length(uv.x+.1+w)+length(uv.y+.1))*str;    
    col += smoothstep(sz, sz+aa, length(uv.x-.1-w)+length(uv.y+.1))*str;
    col += smoothstep(sz, sz+aa, length(uv.x+.1+w)+length(uv.y-.1))*str;
    
    uv *= Rot(-cos(time*.1)*3.1415*4.);
    
    col.rg += smoothstep(sz, sz+aa, length(uv.x+.2+w)+length(uv.y))*str;
    col.rg += smoothstep(sz, sz+aa, length(uv.x-.2-w)+length(uv.y))*str;    
    col.rg += smoothstep(sz, sz+aa, length(uv.x)+length(uv.y-.2-w))*str;
    col.rg += smoothstep(sz, sz+aa, length(uv.x)+length(uv.y+.2+w))*str;
       
    if (uv.y>-.4) col -= vec3(1.-col.r, 1.-col.r, 1.-col.r)*.5;
    if (uv.x>-.4) col -= vec3(1.-col.r, 1.-col.r, 1.-col.r)*.5;
    if (uv.x>-.4) col += vec3(.35, .2, .2);
    
    col += vec3(.02, .03, .0);
    col += Hash21(uv)*.15;
    
    // vignette
    uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    uv *= .6;
    uv.x *= 4.5;
    uv.y -= .5;
    vec3 colOrg = col;
    col *= smoothstep(-.95, .0, uv.y)*1.5;
    col *= smoothstep(0., -.95, uv.y)*1.5;
    col *= smoothstep(-5., 1., uv.x)*1.5;
    col *= smoothstep(5., -1., uv.x)*1.5;
    col = mix(colOrg, col, 0.5);
    col *= 1.04;
    
    glFragColor = vec4(col,1.0);
}

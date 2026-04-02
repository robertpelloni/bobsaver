#version 420

// original https://www.shadertoy.com/view/ttcyzr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

mat2 Rot(float a) {
    float s=sin(a), c=cos(a);
    return mat2(c, -s, s, c);
}

float Circles(vec2 uv, float size) {
    vec2 gv = uv;
    gv *= Rot(time*.3);
    gv.x += atan(0.08, gv.y*gv.y*(sin(time*1.)*.15+.15))*.4-.6;
    
    float d = length(gv);
    float circle = smoothstep(size+.06, size, d);
    
    gv = uv;
    gv *= Rot(-time*.4+5.);
    gv.x += atan(0.09, gv.y*gv.y*(sin(time*.9)*.2+.2))*.4-.6;
    d = length(gv);
    circle += smoothstep(size+.04, size, d);
    
    gv = uv;
    gv *= Rot(time*.3+9.);
    gv.x += atan(0.07, gv.y*gv.y*(sin(time*1.9)*.2+.2))*.4-.6;
    d = length(gv);
    circle += smoothstep(size+.04, size, d);
    
    gv = uv;
    gv *= Rot(-time*.2+13.5);
    gv.x += atan(0.07, gv.y*gv.y*(sin(time*2.1)*.2+.2))*.4-.6;
    d = length(gv);
    circle += smoothstep(size+.04, size, d);
    
    circle = clamp(circle, 0., 1.);
    
    d = length(uv+.03*sin(time));
    circle -= smoothstep(0.4, 0., d)*.14;
    d = length(uv+.02*cos(time*.94));
    circle -= smoothstep(0.17, 0., d)*.03;
                
    return circle;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    uv *= .9;
    vec3 col = vec3(0.);

    float circles = Circles(uv, .17);
    float gradient = smoothstep(0.4, 0.1, length(uv.x-.3+(uv.y*sin(time*.1))));
    gradient *= circles;
    circles += gradient*.5;
    col += circles;
    col *= vec3(0.9, 0.8, 0.4);
    
    col = 1.3-col;
    
    circles = Circles(uv*.9, .205);
    col -= circles * .55;
    col.b += .09;
    col.rg -= .07;
    
    col += smoothstep(0.3, 0.0, length(vec2(uv.x+sin(time*.5)*.18, uv.y+cos(time*.5)*.18)))*.13;
    
    float clo = smoothstep(0.25,0.2, length(vec2(uv.x+sin(time*.5)*.015, uv.y+cos(time*.5)*.015)));
    float cli = smoothstep(0.33,0.0, length(vec2(uv.x+sin(time*.5)*.015, uv.y+cos(time*.5)*.015)));
    clo -= cli;
    
    col -= clo*.15;
    col.b += .1;   
    
    glFragColor = vec4(col,1.0);
}

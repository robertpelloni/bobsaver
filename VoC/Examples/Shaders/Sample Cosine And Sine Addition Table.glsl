#version 420

// original https://www.shadertoy.com/view/NtScRt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define t time*.5

vec2 Grid(in vec2 uv, in vec2 grid, out vec2 cells){
    uv*=grid;
    cells=floor(uv);
    uv=fract(uv);
    return uv;
}

vec2 Position(float x, float y) {
    return vec2(sin(t*(x+1.))*.5+.5,cos(t*(y+1.))*.5+.5)*.75+.125;
}

vec3 Circle(vec2 p, vec2 s) {
    return vec3(smoothstep(0.07,0.08,length(p-s)));
}

void main(void) {
    vec2 uv=gl_FragCoord.xy/resolution.xy;
    uv.x*=resolution.x/resolution.y;
    
    // 0,0 in top left
    uv.y = 1.-uv.y;

    // split the uv into a grid
    vec2 cells;
    uv=Grid(uv,vec2(10.,10.),cells);

    // lines
    vec2 bl = step(vec2(0.01),uv);
    float pct = bl.x * bl.y;
    vec2 tr = step(vec2(0.01),1.0-uv);
    pct *= tr.x * tr.y;
    vec3 lines = vec3(pct);

    // table
    vec2 p = Position(cells.x, cells.y);
    vec3 fill = vec3(cells*.1,1.-cells.x*.1)*.6;

    // left column
    if (cells.x == 0.) {
        fill = fill*.6;
        p = Position(cells.y, cells.y);
    } 
    
    // top row
    if (cells.y == 0.) {
        fill = fill*.6;
        p = Position(cells.x, cells.x);
    } 

    // top left corner
    if (cells.x == 0. && cells.y == 0.) {
        fill = vec3(0.);
        p = vec2(0.5);
    }

    // diagonal
    if (cells.x==cells.y) fill = fill*.6;

    vec3 color = Circle(uv,p)*1.-fill*lines;
    
    glFragColor = vec4(color,1.0);
}

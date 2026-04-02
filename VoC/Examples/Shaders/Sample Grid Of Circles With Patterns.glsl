#version 420

// original https://www.shadertoy.com/view/3dGBWz

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float circle(in vec2 st, in float radius){
    float d=length(st-.5);
    return smoothstep(radius,radius-.01,d);
    
}

// change pattern variable to get different patterns
float generator (in vec2 cell,in float mult) {    
    float pattern;
    pattern=mult*(sin(cell.x*time/7.)+sin(cell.y*time/7.));
    return fract(pattern);
}

void main(void) {
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv.x*=resolution.x/resolution.y;
    float multiplier=0.8754;
    float Ncircles=12.;    
    uv *= Ncircles; 
    vec2 posInt = floor(uv)+1.;  //(i,j) integerr coordinates
    vec2 posFloat = fract(uv); //(u,v) decimal cell coordinates 
    vec3 color =generator(posInt,multiplier) *vec3(1.,.5+.5*cos(time),.5+.5*sin(time));
    color*=circle(posFloat,.5);
    glFragColor = vec4(color,1.0);
}

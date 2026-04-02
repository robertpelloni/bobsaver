#version 420

// original https://www.shadertoy.com/view/wdlXD8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float s3 = 1.73205080757;
const float zoom = 5.;

void main(void) {
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y*zoom;
    
    float minRes = min(resolution.x,resolution.y);
    float eps    = zoom/minRes;
    
    //r are the dimensions of the box we draw around the hexagons
    vec2 r = vec2(1, s3);
    vec2 h = r*.5;
    
       //grid A & B are congruent but shifted versions of each other. They correspond with the red&green grids
    vec2 a = mod(uv, r)-h;
    vec2 b = mod(uv-h, r)-h;
    
    vec2 c = dot(a,a)<dot(b,b)?a:b;
    vec2 id = vec2((uv-c)/h);
 
    //color hexagons corresponding to grid A black and to B grey
    vec3 col = c==a ? vec3(.1) : vec3(.3);
    
    //draw the red and green gridlines
    float t = smoothstep(-1.,1.,cos(time));
    col.r += dot( smoothstep(h-eps,h-eps*.5,abs(a)), vec2(1)) * t;
    col.g += dot( smoothstep(h-eps,h-eps*.5,abs(b)), vec2(1)) * (1.-t);
        ;
    glFragColor = vec4(col,1.0);
}

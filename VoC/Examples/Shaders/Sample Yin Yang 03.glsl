#version 420

// original https://www.shadertoy.com/view/lsd3RB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.1415

float circle(vec2 uv, vec2 p, float size) {
    float dist = length(uv-p);
    float f = fwidth(dist)/4.;
    float circle = smoothstep(size+f, size-f, dist);
    
    return circle;
}

float circle(vec2 uv, vec2 p, float size, float thickness) {
    float dist = length(uv-p);
    
    float circle = smoothstep(thickness+fwidth(dist), thickness, abs(dist-size));
    
    return circle;
}

vec2 rotate(vec2 uv, vec2 p, float angle) {
    float s = sin(angle);
    float c = cos(angle);
    mat2 rot = mat2(c, s, s, -c);
    
    uv -= p;
    uv *= rot;
    uv += p;
    
    return uv;
}

float yinyang(vec2 uv, vec2 p, float size, float angle) {
       uv = rotate(uv, p, angle);
    
    float f = fwidth(uv.x);
    float c = smoothstep(-f, f, uv.x-p.x);
    c *= circle(uv, p, size);
    float s2 = size*.5;
    
    c *= 1.-circle(uv, vec2(p.x, p.y+s2), s2);
    c += circle(uv, vec2(p.x, p.y-s2), s2);   // this cause edgelines
    c += circle(uv, p, size+0.001, 0.001);
    
    float s3 = s2*.25;
    c += circle(uv, vec2(p.x, p.y+s2), s3);
    c *= 1.-circle(uv, vec2(p.x, p.y-s2), s3); 
    
    return clamp(c, 0., 1.);
}

void main(void)
{
    float grid = 4.;
    float iGrid = 1./grid;
     float t = time*2.;
    
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    
    float aspect = resolution.x/resolution.y;
    vec2 uv1 = uv-vec2(.5);
    
    uv.x-=.5;
    uv.x *= aspect;
    
    uv.y-=0.5;
       float zoom = 4.-cos(t*.05)*2.5;
    uv *= zoom;
   // uv *= 1.+length(uv)*.2;
    uv.y+=0.5;
    
    uv = rotate(uv, vec2(.0, 0.5), -t*0.01);
    
    
    
    vec4 col = vec4(0.);
    
   
    vec2 uv2 = mod(uv+vec2(iGrid)*.5, iGrid)*grid-0.5;
    
    float angle = atan(uv.x, uv.y-iGrid*2.);
    float dist = t+(uv.x*uv.y);//+pow(sin(t+angle), 4.);
    dist = length(uv1);
    col += yinyang(uv2, vec2(.0), .4, dist*20.+t);
 
    vec4 bg = mix(vec4(1.), vec4(0.), dist);
    
    col = mix(bg, vec4(0.), col);
    
    glFragColor = col;
}

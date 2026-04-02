#version 420

// original https://www.shadertoy.com/view/wlKSW3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float hash21(vec2 uv){
    uv = fract(uv *vec2(62026.3504,74514.74));
    uv += dot(uv,uv+vec2(65.408,83.54));
    return fract(uv.x*uv.y);
}
float sq(vec2 uv,vec2 s) {
    uv.y += hash21(vec2(floor(uv.x*10.))) + tan(floor(uv.x*10.)+time*hash21(vec2(floor(uv.x*10.)+.1)))*.1;
    s.y += hash21(floor(uv*100.));
    vec2 d = abs(uv) - s;
    float sqr = length(max(d,0.0)) + min(max(d.x,d.y),0.0);
    return smoothstep(0.00021,0.0002,sqr);
    
}
void main(void)
{
    vec2 uv = (gl_FragCoord.xy -.5* resolution.xy)/resolution.y;

    float d = sq(uv,vec2(1.,.13));
    vec3 col = vec3(.0);
    col.g = d*.9*log2(2.-fract(time*.33))/hash21(vec2(floor(uv.x*100.)));
    col.b = d*.9*log2(2.-fract(time*.66))/hash21(vec2(floor(uv.x*75.)));
    
    col *= smoothstep(1.0,.5*cos(uv.y*10.+time),length(uv));
    glFragColor = vec4(col,1.0);
}

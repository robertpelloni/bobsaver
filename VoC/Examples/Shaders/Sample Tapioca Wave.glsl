#version 420

// original https://www.shadertoy.com/view/wl2XRD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float circle(vec2 p,vec2 o,float r){
    return length(p - o) - r;
}
float dist_1(vec2 p){
    float wave0 = p.y + 0.8 - 0.15 * cos(p.x * 5.0) * cos(time * 2.0);
    float wave1 = p.y + 0.3 - 0.15 * cos(p.x * 5.0) * cos(time * 2.0);
    float wave2 = p.y - 0.3 - 0.15 * cos(p.x * 5.0) * cos(time * 2.0);
    float wave3 = p.y - 0.8 - 0.15 * cos(p.x * 5.0) * cos(time * 2.0);
    return min(min(wave0,-wave3),max(-wave1,wave2));
    
}
float dist_2(vec2 p){
    float result = 100000.0;
    for(float xi = -3.0; xi < 3.0; xi += 0.1){
        for(float yi = -3.0; yi < 3.0; yi += 0.1){
            vec2 tmp = vec2(xi+fract(cos(yi * 3.0)*time / 4.),yi);
            float r = 0.04 - max(dist_1(tmp),0.00);
            result = min(result,circle(p,tmp,r));
        }
    }
    return result;
}
void main(void)
{
    vec2 uv = (gl_FragCoord.xy * 2.0 - resolution.xy) / min(resolution.x, resolution.y);
    vec3 col = dist_2(uv) > 0. ? vec3(252,193,121)/255. : vec3(159,101,101)/255.;
    glFragColor = vec4(col,1.0);
    
}

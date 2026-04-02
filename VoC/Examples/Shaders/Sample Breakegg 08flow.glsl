#version 420

// original https://www.shadertoy.com/view/wl2XDW

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float sat(float f){
    return clamp(f,0.,1.);
}
float N21(vec2 p){
    return fract(sin(p.x*100.+p.y*6574.)*5647.);
}

float SmoothNoise(vec2 uv){
    vec2 lv = fract(uv);
    //vec2 lv = smoothstep(0.,1.,fract(uv*10.));
    vec2 id = floor(uv);
    
    lv = lv*lv*(3.-2.*lv);
    
    float bl = N21(id);
    float br = N21(id+vec2(1,0));
    float b = mix(bl, br, lv.x);
    
    float tl = N21(id+vec2(0,1));
    float tr = N21(id+vec2(1,1));
    float t = mix(tl, tr, lv.x);

    return mix(b, t, lv.y);
}
float SmoothNoise2(vec2 uv) {
    float c = SmoothNoise(uv*4.);
    
    // don't make octaves exactly twice as small
    // this way the pattern will look more random and repeat less
    c += SmoothNoise(uv*8.2)*.5;
    c += SmoothNoise(uv*16.7)*.25;
    c += SmoothNoise(uv*32.4)*.125;
    c += SmoothNoise(uv*64.5)*.0625;
    
    c /= 2.;
    
    return c;
}
vec3 MyMain(vec2 uv){
    // float c = N21(uv);
    vec3 col = vec3(0);
    
    float c1 = uv.x >0. ? SmoothNoise2(uv + vec2(time*.2,0))*1.: 0.;
    c1 = uv.x >0. ? sat(c1/1.+0.2) : 0.;
    vec3 col1 = vec3(0.6614848971366882 ,0.3401336669921875,0.07421875)*c1;
    //col1 = mix(vec3(1),col1, c1);
    
    float c2 = uv.x <6. ? SmoothNoise2(uv - vec2(time*.2,0))*1. : 0.;
    c2 = uv.x <6. ? sat(c2/1.+.2) : 0.;
    vec3 col2 = vec3(0.18359375,0.33359375,0.25234375)*c2;
    //col2 = mix(vec3(1),col2, c2);
    
    float f = smoothstep(0.2, 0.7, uv.x);
    float f2 = smoothstep(0.8, 0.3, uv.x);
    col1 = mix(vec3(1), col1, f);
    col2 = mix(vec3(1), col2, f2);
    //col = mix(col2, col1, uv.x*1.);
    col = min(col1,col2);
    return col;
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    
    vec3 col = MyMain(uv);
    //vec3 col = vec3(SmoothNoise2(uv));
    
    glFragColor = vec4(col,1.0);
}

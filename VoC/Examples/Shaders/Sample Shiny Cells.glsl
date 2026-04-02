#version 420

// original https://www.shadertoy.com/view/3dGGRK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 R;
vec2 hash21(float p){
    vec3 p3 = fract(vec3(p) * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.xx+p3.yz)*p3.zy);
}
vec3 cellcol(float p){
    return fract(vec3(sin(p)*10.,cos(p)*12., cos(p+12.3)*14.));
}

vec2 V(vec2 uv){
    float md = 99.;
    float id = 0.;
    for(float i = 0.0; i < 80.; i++)
    {
        vec2 p = hash21(i) - .5; 
        p.x += sin(time*.25 + i)*0.5;
        p.y += sin(time*.125 + i)*0.5;
        float d = length(uv - p);
        
        if(d < md)
            id = i;
        
        md = min(md, d);
    }
     return vec2(md, id);   
}

void main(void) {

    vec2 u = gl_FragCoord.xy;

    R = resolution.xy;
    vec2 uv = vec2(u.xy - 0.5*R.xy)/R.y;
    vec3 col = vec3(1);
    
    uv.x += mod(time*.15, 2.) * (mod(floor(time*.15),2.)*2.);
    uv.y += mod(time*.15+1., 2.) * (mod(floor(time*.15+1.),2.)*2.);
    
    uv = fract(uv)-.5;
    vec2 id = floor(uv);
    vec2 flip = mod(id, 2.);
    
    uv *= 2.*flip - 1.;
    
    vec2 v = V(uv);
    
    col = cellcol(v.y+.5)*.7;
    col *= smoothstep(.26, .0,v.x);
    float l = exp(-v.x*28.)*.6;
    
    col += vec3(0.7, 0.6, 0.1)*l;
    
    glFragColor = vec4(col, 1.0);
    
}

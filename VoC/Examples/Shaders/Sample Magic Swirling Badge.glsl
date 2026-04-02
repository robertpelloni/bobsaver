#version 420

// original https://www.shadertoy.com/view/csXXRr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define TWOPI   6.283185307179586476925286766559
float snoise(vec3 uv, float res)
{
    const vec3 s = vec3(1e0, 1e2, 1e3);
    
    uv *= res;
    
    vec3 uv0 = floor(mod(uv, res))*s;
    vec3 uv1 = floor(mod(uv+vec3(1.), res))*s;
    
    vec3 f = fract(uv); f = f*f*(3.0-2.0*f);

    vec4 v = vec4(uv0.x+uv0.y+uv0.z, uv1.x+uv0.y+uv0.z,
                    uv0.x+uv1.y+uv0.z, uv1.x+uv1.y+uv0.z);

    vec4 r = fract(sin(v*1e-1)*1e3);
    float r0 = mix(mix(r.x, r.y, f.x), mix(r.z, r.w, f.x), f.y);
    
    r = fract(sin((v + uv1.z - uv0.z)*1e-1)*1e3);
    float r1 = mix(mix(r.x, r.y, f.x), mix(r.z, r.w, f.x), f.y);
    
    return mix(r0, r1, f.z)*2.-1.;
}

void main(void)
{
    vec2 p = -.5 + gl_FragCoord.xy / resolution.xy;
    p.x *= resolution.x/resolution.y;
    
    float color ;
    float dist = length(p);
    
    color = cos(3.*dist);
    vec3 coord ;
    
    float angle = atan(p.x,p.y);
    
    coord.x = angle/TWOPI+.5;
    coord.y = sin(4.*cos(2.*log(2.*dist))- 3.*(mod(angle, TWOPI))); 
    coord.z =.5;
    
    
    float power = 2.0;
    color += (1.5 / power) * snoise(coord + vec3(time*0.03,time*0.03 , time*.03), power*16.) ;
    
    glFragColor = vec4(  pow(max(color,0.),3.)*0.4, pow(max(color,0.),2.)*0.5, color , 1.0);
    
    
    

    
}

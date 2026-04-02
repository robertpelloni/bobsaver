#version 420

// original https://www.shadertoy.com/view/Mt2fDd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define rot(spin) mat2(sin(spin),cos(spin),cos(spin),-sin(spin))

float map(vec2 p, float slice)
{
    vec2 offset = vec2(sin(slice*0.1+time*0.3),cos(slice*0.1+time*0.3));
    p = fract(p*0.1+offset)*10.0-5.0;
    return length(p)-((sin(floor(slice))*sin(time))*0.2+0.45)*2.5;
}

vec2 findnormal(vec2 p, float slice, float len) {
    vec2 eps = vec2(0.0,0.01);
    return normalize(vec2(
        map(p+eps.yx,slice),
        map(p+eps.xy,slice))-
        len);
} 

void main(void)
{
    glFragColor = vec4(0);
    vec2 uv = (gl_FragCoord.xy * 2.0 - resolution.xy) / resolution.y;
    
    vec3 ro = vec3(0.0,time*3.0,0.0);
    vec3 rd = normalize(vec3(uv,1.0));
    
    //rd.zy *= rot(mouse*resolution.xy.y/resolution.y*3.14+3.14);
    //rd.zx *= rot(-mouse*resolution.xy.x/resolution.x*6.28+3.14*0.5);
    bool hit = false;
    float len;
    float dist = 0.0;
    
    vec3 floorpos = floor(ro);
    vec3 signdir = sign(rd);
    float inv = 1.0/(abs(rd.y)+0.0001);
    
    float limit = inv*abs((signdir.y*0.5+0.5)-fract(ro.y));
    
    float slice = floor(ro.y);
    
    bool hitside = false;
    
    for (int i = 0; i < 200; i++)
    {
        len = map(ro.xz,slice);
        
        if (len < 0.01||dist>100.0)
        {
            hit = len < 0.01;
            break;
        }
        
        hitside = false;
        
        len = min(limit,len);
        limit -= len;
        ro += rd*len;
        dist += len;
        
        if (limit == len)
        {
            limit = inv;
            slice+=signdir.y;
            
            hitside = true;
            
            //break;
        }
    }
    if (dist < 100.0)
    {
        vec3 normal;
        if (hitside)
        {
            normal = vec3(0,-signdir.y,0);
        } else {
            normal = vec3(findnormal(ro.xz,slice,len),0.0).xzy;
        }
        
        vec3 lightdir = vec3(-1);
        
        vec3 col = vec3(1.0,0.3,0.0);
        if (hitside) col = vec3(1.0,0.2,0.1);
        
        
        float ambient = 0.2;
        
        float diffusion = clamp(dot(-lightdir,normal),ambient,1.0);
        
        glFragColor = vec4(col*diffusion,1.0);
        
        glFragColor /= dist*dist*0.005+1.0;
        
    }
    glFragColor = sqrt(glFragColor);
}

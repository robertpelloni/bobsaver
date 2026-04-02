#version 420

// original https://www.shadertoy.com/view/MlX3RB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159

mat3 xrot(float t)
{
    return mat3(1.0, 0.0, 0.0,
                0.0, cos(t), -sin(t),
                0.0, sin(t), cos(t));
}

mat3 yrot(float t)
{
    return mat3(cos(t), 0.0, -sin(t),
                0.0, 1.0, 0.0,
                sin(t), 0.0, cos(t));
}

mat3 zrot(float t)
{
    return mat3(cos(t), -sin(t), 0.0,
                sin(t), cos(t), 0.0,
                0.0, 0.0, 1.0);
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    
    uv = uv * 2.0 - 1.0;
    
    uv.x *= resolution.x / resolution.y;
    
    vec3 eye = normalize(vec3(uv,1.0-dot(uv,uv)*0.5));
    
    float t=0.0;
    float d = 0.0;
    vec3 col=vec3(0.0);
    
    for(int i = 0; i < 16; ++i){
        vec3 pos = eye*t;
        
        pos = pos * xrot(-PI/4.0) * yrot(-PI/4.0);
        
        float theta = time;
        pos = pos * xrot(theta) * yrot(theta) * zrot(theta);
        
        pos.z += time;
        pos.y += 0.25 + time;
           pos.x += 0.5 + time;
        
        vec3 coord = floor(pos);
           pos = (pos - coord) - 0.5;
        
        d = length(pos)-0.2;
        float idx = dot(coord,vec3(1.0));
        idx = floor(fract(idx/3.0)*3.0);
        if(idx==0.0){
            col = vec3(1.0, 0.0, 0.0);
        }else if(idx==1.0){
            col = vec3(0.0, 1.0, 0.0);
        }else if(idx==2.0){
            col = vec3(0.0, 0.0, 1.0);
        }
        
        float k;
        
        k = length(pos.xy)-0.05;
        if(k<d){
            d=k;
            col=vec3(1.0,1.0,1.0);
        }
        
        k = length(pos.xz)-0.05;
        if(k<d){
            d=k;
            col=vec3(1.0,1.0,1.0);
        }
        
        k = length(pos.yz)-0.05;
        if(k<d){
            d=k;
            col=vec3(1.0,1.0,1.0);
        }
        
        t+=d;
    }
    
    float fog = 1.0 / (1.0 + t*t*0.5 + d*100.0);
    
    glFragColor = vec4(fog*col, 1.0);
}

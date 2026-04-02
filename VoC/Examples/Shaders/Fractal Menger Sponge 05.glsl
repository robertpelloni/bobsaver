#version 420

// original https://www.shadertoy.com/view/lssyW2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float map(vec3 p) {
    p = mod(p,3.0);
    return dot(p-1.0,p-1.0)-1.0;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy * 2.0 - resolution.xy) / resolution.y;
    
    vec3 pos = vec3(1.5,1.5,time);
    vec3 dir = normalize(vec3(uv,1.0));
    vec3 floorpos = floor(pos);
    vec3 mask;
    
    float dist = 0.0;
    vec3 localpos = pos;
    vec3 localfloor = floorpos;
    float stepsize = 1.0;
    float count = 0.0;
    
    
    for (int i = 0; i < 8; i++) {
        float len = map(localfloor);
        if (len > 0.0) {
            localpos *= 3.0;
            localpos = localpos-sign(dir)*1.5+1.5;
            
            localfloor = floor(localpos-sign(dir)*0.001);
            stepsize /= 3.0;
            if (count > 2.0) {
                break;
            }
            count ++;
        }
        
        vec3 dists = abs((sign(dir)*0.5+0.5)-(localpos-localfloor))*1.0/abs(dir);
        
        float m = min(min(dists.x,dists.y),dists.z);
        
        mask = step(dists,vec3(m));
        
        pos += m*dir*stepsize;
        dist += m*stepsize;
        localpos += m*dir;
        localfloor += mask*sign(dir);
        
        floorpos += mask*sign(dir)*stepsize;
    }
    
    glFragColor = vec4(mask,1.0);
}

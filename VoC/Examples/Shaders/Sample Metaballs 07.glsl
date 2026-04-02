#version 420

// original https://www.shadertoy.com/view/XslBWX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float dot2(vec3 p) {
    return dot(p,p);
}

float map(vec3 p) {
    float len = 0.0;
    
    for(float i = 1.0; i < 20.0; i++) {
        len += 1.0/(dot2(p-vec3(sin(time*i*0.1),cos(time*i*0.12),0.0)*10.0));
    }
    
    return inversesqrt(len)-1.0;
}

vec3 findcolor(vec3 p) {
    float len = 10000.0;
    vec3 color = vec3(0.0);
    for(float i = 1.0; i < 20.0; i++) {
        float len2 = (dot2(p-vec3(sin(time*i*0.1),cos(time*i*0.12),0.0)*10.0));
        
        //random colors
        color = mix(vec3(sin(i*9.11)*0.5+0.5,fract(1.0/fract(i*3.14)),fract(i*3.14)),
                    color, clamp((len2-len)*0.1+0.5,0.0,1.0));
        
        len = mix(len2,len,clamp((len2-len)*0.1+0.5,0.0,1.0));
    }
    return color;
}

vec3 findnormal(vec3 p) {
    vec2 eps = vec2(0.01,0.0);
    
    return normalize(vec3(
        map(p+eps.xyy)-map(p-eps.xyy),
        map(p+eps.yxy)-map(p-eps.yxy),
        map(p+eps.yyx)-map(p-eps.yyx)));
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy*2.0-resolution.xy) / resolution.y;
    
    vec3 ro = vec3(0.0,0.0,-15.0);
    vec3 rd = normalize(vec3(uv,1));
    float len = 0.0;
    float dist = 0.0;
    
    for (int i = 0; i < 100; i++) {
        len = map(ro);
        dist += len;
        ro += rd * len;
        if (dist > 30.0 || len < 0.01) {
            break;
        }
    }
    
    if (dist < 30.0 && len < 0.01) {
        vec3 sun = normalize(vec3(-1.0));
        vec3 objnorm = findnormal(ro);
        vec3 reflectnorm = reflect(rd,objnorm);
        vec3 color = findcolor(ro);
        glFragColor = vec4(color*max(0.2,0.8*dot(objnorm,sun)),1.0);
        glFragColor = max(glFragColor,(dot(reflectnorm,sun)-0.9)*12.0);
    }
}

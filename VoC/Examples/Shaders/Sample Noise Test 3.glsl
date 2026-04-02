#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/XtyyWw

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float grad(int hash,float x,float y){
    int h = hash & 1;
    return float(h);
}

float hash(vec2 uv){
    int a = int(fract(1234.1234* cos(1234.1234 * sin(dot(uv,vec2(2.,72.)))))*10.);
    return grad(a,uv.x,uv.y);
}

float fade(float t){
    return t * t * t * (t * (t * 6. - 15.) + 10.);
}

float noise(vec2 uv){
    
    vec2 i = floor(uv);
    vec2 f = fract(uv);
    f = f * f * (3. - 2. * f);
    f.x = fade(f.x);
    f.y = fade(f.y);
    vec2 o = vec2(1.,0.);
    
    float m = mix(
        floor(mix(hash(i + o.yy), hash(i + o.xy), f.x)*20.),
        floor(mix(hash(i + o.yx), hash(i + o.xx), f.x)*20.),
        f.y
    );
    
    
    return m;
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (gl_FragCoord.xy*2. - resolution.xy)/resolution.y +2.;

    vec3 col1 = vec3(0.7,0.4,0.5);
    vec3 col2 = vec3(0.9,0.7,0.8);
    
//    vec3 col1 = vec3(0.,0.,0.);
//    vec3 col2 = vec3(.5,.5,.5);
    
    float speed = 7.;
    
    float scale = 10.;
    vec3 col = min(max(vec3(.1 + max(noise(uv * scale + time*speed ) - .2,0.)) - 0.5,0.)+ col1,1.)  * col2;

    if(uv.x<2.){
        col =1. - col;
    }
    if(uv.x>1.995 && uv.x<2.008){
        col=vec3(0.2,0.2,0.4);
    }
   
    glFragColor = vec4(col,1.0);
}

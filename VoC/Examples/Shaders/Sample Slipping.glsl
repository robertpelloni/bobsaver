#version 420

// original https://www.shadertoy.com/view/XlscDl

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float time2(float t){
    float tt = floor(t)+smoothstep(0.0,1.0,fract(t));
    //t=floor(tt)+smoothstep(0.0,1.0,fract(tt));
    return tt;
}

float map(vec3 p){
    p+=0.25;
    vec3 q = fract(p+0.5) * 2.0 - 1.0;
    vec3 q2 = fract(p) * 2.0 - 1.0;
    vec3 r = floor(p);
    vec3 s = mod(r, 1.0);
    
    return min(
        length(q2)-0.5
        ,
        min(length(q.xy), min(length(q.xz), length(q.yz))) - 0.02
    );    
}

float trace(vec3 o, vec3 r){
    float t = 0.0;
    
    for (int i=0;i<int(pow(2.0,3.5+sin(time/4.0)*2.0)); ++i){
        vec3 p = o + r * t;
        float d = map(p);
        t += d * 0.5;
    }
    
    return t;
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    
    uv = uv * 2.0 - 1.0;
    
    uv.x *= resolution.x / resolution.y;
    float off = sin(uv.x+time2(time/2.0))*sin(uv.y-time/2.0);
    vec3 r = normalize(vec3(uv, 2.0+off));
    
    
    float the = time2(time/3.0);
    r.xz *= mat2(cos(the), -sin(the), sin(the), cos(the));
    the = time2(time/4.0);
    r.xy *= mat2(cos(the), -sin(the), sin(the), cos(the));
    the = time2(time/6.0);
    r.yz *= mat2(cos(the), -sin(the), sin(the), cos(the));
                  
    vec3 o = vec3(time2(time/3.0), 0.0, time2(time));
                  
    float t = trace(o,r);
                  
    float fog = 1.0 / (1.0 + t * t * 0.1);
    fog = pow(fog,4.5-sin(time2(time/4.0))*4.0);
       vec3 fc = vec3(fog); 
   
    glFragColor = vec4(fc,1.0);
}

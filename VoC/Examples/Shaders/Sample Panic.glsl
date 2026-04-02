#version 420

// original https://www.shadertoy.com/view/4tByzR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float time2(float t){
    //return t*0.3;
    float tt = t;
    tt = floor(tt)+smoothstep(0.0,1.0,fract(tt));
    //t=floor(tt)+smoothstep(0.0,1.0,fract(tt));
    return tt;
}

float PI = 3.14159265359;

float map(vec3 p, float roff){
    p = fract(p)*2.0-1.0;
    float the = time2(time/3.0+roff);
    p.xz *= mat2(cos(the), -sin(the), sin(the), cos(the));
    the = time2(time*1.0);
    p.xy *= mat2(cos(the), -sin(the), sin(the), cos(the));
    the = time2(time/6.0);
    p.yz *= mat2(cos(the), -sin(the), sin(the), cos(the));
    float m = sin(time*2.0)*0.5+0.5;
    float m1 = pow(m,0.5);
    float m2 = pow(1.0-m,0.5);
    float d1 = length(p)-mix(0.0,0.6,m1)+sin(time+roff)*0.15;
    float d2 = length(max(abs(p)-vec3(1.0,1.0,1.0)*mix(0.0,0.4,m2),0.0));
    return min(d1,d2);
}

float trace(vec3 o, vec3 r, float roff){
    float t = 0.0;
    vec3 p = o;
    float d = 1.0;
    float iter = 0.0;
    float m = sin(time/4.0)*0.5+0.5;
    float max_iter = mix(12.0,48.0,m);
    float hit = 0.0001;
    while(d>hit && iter<max_iter){
        //vec3 p = o + r * t;
        d = map(p,roff+length(o-p)*2.0)*0.5;
        p+=r*d;
        t += d;
        iter++;
    }
    
    return t*float(iter)/float(max_iter);
}

vec3 getR(vec2 uv, float off){
    vec3 r = normalize(vec3(uv, 2.0+off));
    float the = time2(time/3.0);
    r.xz *= mat2(cos(the), -sin(the), sin(the), cos(the));
    the = time2(time/4.0);
    r.xy *= mat2(cos(the), -sin(the), sin(the), cos(the));
    the = time2(time/6.0);
    r.yz *= mat2(cos(the), -sin(the), sin(the), cos(the));
    return r;
}

vec3 doIm( float t, vec2 gl_FragCoord )
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    
    uv = uv * 2.0 - 1.0;
    
    uv.x *= resolution.x / resolution.y;
                  
    vec3 o = vec3(time2(time2(time2(t/1.0))), time2(time2(time2(t/1.0+0.5))), 0.0);
    //vec3 o = vec3(0.0,0.0,0.0);  
    float off = sin(uv.x+time2(t/2.0))*sin(uv.y-time2(t/2.0));
    vec3 r = getR(uv, off);
    float ttr = trace(o,r,0.0);
    off = sin(uv.x+time2(t/2.0)+0.03)*sin(uv.y-time2(t/2.0)-0.05);
    r = getR(uv, off);
    float ttg = trace(o,r,0.2);
    off = sin(uv.x+time2(t/2.0)-0.05)*sin(uv.y-time2(t/2.0)+0.03);
    r = getR(uv, off);
    float ttb = trace(o,r,0.4);
                  
    float fogr = 1.0 / (1.0 + ttr * ttr * 0.1);
    float fogg = 1.0 / (1.0 + ttg * ttg * 0.1);
    float fogb = 1.0 / (1.0 + ttb * ttb * 0.1);
       vec3 col = vec3(fogr,fogg,fogb)*0.9;
    return col;
}

void main(void)
{
    float mv = 0.5-sin(time2(time/4.0))*0.5;
    glFragColor = vec4(doIm(time,gl_FragCoord.xy),1);
    
}

#version 420

// original https://www.shadertoy.com/view/3slXWS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define CS(a) vec2(cos(a),sin(a))

float random(in vec2 st)
{
    return fract(sin(dot(st.xy,vec2(12.443,78.4)))*43758.2);
}

float noise(in vec2 st)
{
    vec2 i=floor(st);
    vec2 f=fract(st);
    float a=random(i);
    float b=random(i+vec2(1.0,0.0));
    float c=random(i+vec2(0.0,1.0));
    float d=random(i+vec2(1.0,1.0));
    
    vec2 u=smoothstep(0.0,1.0,f);
    return mix(a,b,u.x)+(c-a)*u.y*(1.0-u.x)+(d-b)*u.x*u.y;
    
}
float circle(vec2 p,float scale)
{
    float f = 0.0;
    p.x+=sin(p.y*20.0+time*10.)*0.05;
    f += 0.04/abs(length(p)- 0.1*scale);
    return f;
}

void main(void)
{
    vec2 p=(gl_FragCoord.xy*2.0-resolution.xy)/min(resolution.x,resolution.y);
    vec3 colA = vec3(0.2, 0.7, 1.0);
    vec3 colB = vec3(0.9, 0.2, 0.0);
    float f = 0.0;
    
    p.x+=sin(p.y*20.0+time*10.)*0.05;
    float d=circle(p,5.);
    p.x+=sin(p.y*20.0+time*20.)*0.05;
    float h=circle(p,5.4);
    
    vec3 k=mix(d*colA,h*colB,abs(sin(time)));
    
    glFragColor = vec4(k,1.);

}

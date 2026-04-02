#version 420

// original https://www.shadertoy.com/view/wt33DX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float torus(vec3 p, vec2 r)
{   p.yz *= mat2(cos(1.57),-sin(1.57),sin(1.57),cos(1.57)); 
    vec3 q = fract(p)*2.0 -1.0;
    float x = length(q.xz)-r.x;
    return length(vec2(x,q.y))-r.y;
}

float trace (vec3 o,vec3 r)
{
    float t = 0.0;
    for(int i=0;i<100;i++)
    {
        vec3 p = o+r*t;
        float d = torus(p-vec3(0.0,0.0,0.0),vec2(1.1,mix(0.01,0.015,sin(time))));
        t+=d*0.09;
    }
    return t;
}

void main(void)
{
    
    vec2 uv = vec2(gl_FragCoord.x/resolution.x,gl_FragCoord.y/resolution.y);
    uv-= 0.5;
    uv/= vec2(resolution.y/resolution.x,1.0);
    
    vec3 r = normalize(vec3(uv,1.0));
    float tt = time*0.15;
    r.xy *= mat2(cos(tt),-sin(tt),sin(tt),cos(tt)); 
    vec3 o = vec3(0,0,tt*2.0);
    
    float t = trace(o,r);

    vec3 col = vec3(1, 0.85, 0);
    float fog = 1.0/(1.0+t*t*0.2); 
    glFragColor = vec4(vec3(col)*fog,1.0)*2.0;
}

#version 420

// original https://www.shadertoy.com/view/3dXcRr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float sphere(vec3 p, float t)
{   
    return length(p)-t;
}

float trace (vec3 o,vec3 r)
{
    float t = mix(1.0,3.0,sin(time*0.5));
    for(int i=0;i<100;i++)
    {
        vec3 p = o+r*t;
        vec3 q = fract(p)*2.0 -1.0;
        float d = sphere(q-vec3(0,0,0),0.75);

        t+=d*0.5;
    }
    return t;
}

void main(void)
{
    vec2 uv = vec2(gl_FragCoord.xy.x/resolution.x,gl_FragCoord.xy.y/resolution.y);
    uv-= 0.5;
    uv/= vec2(resolution.y/resolution.x,1.0);
    
    float u = length(uv);
    float a = atan(resolution.y, resolution.x);
    float v = sin(10.0*(sqrt(u)-0.02*a-0.3*time));
    
    vec3 r = normalize(vec3(uv,0.1));
    float tt = time*0.5;
    r.xy *= mat2(cos(v),sin(v),-sin(v),cos(v)); 
    vec3 o = vec3(0,0,tt);

    float t = trace(o,r);

    float fog = 0.5/(1.0+t*t*1.0); 
    glFragColor = vec4(vec3(fog+vec3(0,0,0.3)),1.0);
}

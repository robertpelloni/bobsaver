#version 420

// original https://www.shadertoy.com/view/3ds3zN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float DE(vec3 p)
{
    vec3 original = p; 
    p /= max(dot(p,p),0.9)*0.7;
    float inflation = 1.01;
    float rod = 0.3;
    p.xz *= mat2(cos(time),-sin(time),sin(time),cos(time));
    p.yz *= mat2(cos(time),-sin(time),sin(time),cos(time));
    p.x = clamp(abs(p.x),rod,1. - rod);
    p *= inflation;
    p.y = clamp(abs(p.y),rod,1. - rod);
    p *= inflation;
    p.z = clamp(abs(p.z),rod,1. - rod);
    p *= inflation;
    p = fract(p) * 2. - 1.;
    return min(length(p) - 0.5, length(original)- rod);   
}

vec3 normal(vec3 p)
{
    vec3 eps = vec3(0.002,0.,0.);
    return normalize(vec3(
        DE(p - eps) - DE(p + eps),
        DE(p - eps.yxy) - DE(p + eps.yxy),
        DE(p - eps.yyx) - DE(p + eps.yyx)
    ));
}

vec2 march(vec3 ro, vec3 rd)
{
    float t = 0.0;
    bool hit = false;
    for(int i = 0; i < 1000; ++i)
    {
        float s = DE(ro + rd * t);
        t += s;
        if(s < 0.02) hit = true;
        if(s < 0.02 || t > 50.) break;
    }
    
    return vec2(t,hit);
}

vec3 render (vec3 ro, vec3 rd)
{
    vec2 hit = march(ro,rd);
    
    if(hit.y > 0.)
    {
        float t = hit.x;
        vec3 p = ro + rd * t;
        vec3 n = normal(p);
        float dist = distance(p,vec3(0.));
        float torch = exp(-pow(dist,3.)*0.5);  
        vec3 light = p - ro;
        light = normalize(light); 
        vec3 base = vec3(1.) * max(dot(n,light) * torch,0.05);
        base *= max(max(dot(n,light),0.1) * max(dot(n,rd),0.5),0.2);
        return base;
    }
    return vec3(0.);  
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = -1. + 2. * gl_FragCoord.xy/resolution.xy;
    uv.x *= resolution.x / resolution.y;
    vec3 ro = vec3(0.,0.,-4.);
    vec3 rd = normalize(vec3(uv,1.));
    // Output to screen
    glFragColor.rgb = pow(render(ro,rd),vec3(0.45));
}

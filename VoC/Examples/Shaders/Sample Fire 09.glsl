#version 420

// original https://www.shadertoy.com/view/ttj3zh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const vec3 yellow = vec3(1,1,0);
const vec3 orange = vec3(1,0.6,0);
const vec3 red = vec3(1,0,0);

float mySmooth(float x)
{
    return x*x*(3. - 2.*x);
}

float rand(vec2 co)
{
    return fract(sin(dot(co.xy + 100. ,vec2(13.9898, 71.233))) * 49.5453);
}

float perlin(vec2 uv)
{
    vec2 ij = floor(uv);
    
    float g1 = rand(ij + vec2(0, 0));
    float g2 = rand(ij + vec2(1, 0));
    float g3 = rand(ij + vec2(0, 1));
    float g4 = rand(ij + vec2(1, 1));
    
    vec2 luv = fract(uv);
    luv = smoothstep(0., 1., luv);
    
    float g12 = mix(g1, g2, luv.x);
    float g34 = mix(g3, g4, luv.x);
    
    float g1234 = mix(g12, g34, luv.y);
    
    return g1234;
}

float noise(vec2 uv)
{
    float result = 0.;
    for (int i = 0; i < 5; i++)
    {
        float p = pow(2., float(i));
        
        result += perlin(uv * p) / p;
    }
    return result * 0.5;
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.x;
    float x = (1.-uv.y);
    x = pow(x, 4.);
    float g = (abs(uv.x - 0.5));
    g = smoothstep(0., 1., pow(g * 1., 0.5)) * 1.6 + 0.5;
    
    uv *= 10.;
    uv.y -= time*4.;
    
    float y = noise(uv) * g;
    float l1 = step(y,x) - step(y,x-0.2);
    float l2 = step(y, x - 0.2) - step(y, x - 0.4);
    vec3 col = mix(yellow, red, l1);
    col = mix(col, orange, l2);
    
    glFragColor = vec4(col * step(y,x), 1);
    //glFragColor = vec4(x);

}

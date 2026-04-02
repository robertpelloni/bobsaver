#version 420

// original https://www.shadertoy.com/view/Wl3GzX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// default
const float uBump = 0.03;
const vec3 uColor = vec3(2.4,5.8,5.2);
const vec3 uColorDiff = vec3(0.5,1,0.5);
const vec3 uLightDir = vec3(0.2,0.2,0);
const float uSmooth = 3.2;
const float uSpeed = 1.0;
const float uTwist = 1.7;
const float n = 5.0;
    
float shape(vec2 p)
{
    float pin = 3.14159/n;
    
    float l = length(p);
    float a = atan(p.x, p.y);
    a += time * uSpeed - l * uTwist;
    a = mod(a, pin)-pin/2.0;
    
    vec2 uv = vec2(cos(a) * 0.25 ,sin(a)) * l;
    uv.x -= 0.1;
    float m = 0.008 / dot(uv,uv) - 2.25 * sin(p.x * 1.5);
    m = sqrt(m*m+uSmooth) - 2.25;
    
    return m;
}

void main(void)
{
    vec2 g = gl_FragCoord.xy;

    vec2 uv = (g*2.0-resolution.xy) / min(resolution.x, resolution.y)*0.75;
    vec3 rd = normalize(vec3(uv, 1.));

    float eps = 2.0/min(resolution.x, resolution.y);
    float f = shape(uv);
    float fx = (shape(uv + vec2(eps,0))-f)/eps;
    float fy = (shape(uv + vec2(0,eps))-f)/eps;
    vec3 n = normalize( vec3(0., 0., -1) + vec3(fx, fy, -1.) * uBump );           
    vec3 ld = normalize(uLightDir);
    
    vec3 col = f * (sin(uColor)*0.5+0.5);
    float diff = max(dot(n, ld), 0.);  
    float spec = pow(max(dot( reflect(-ld, n), -rd), 0.), 12.); 
    col += diff * uColorDiff + spec;
    
    glFragColor.rgb = col;
    glFragColor.a = 1.0;
}

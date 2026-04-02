#version 420

// original https://www.shadertoy.com/view/Wtjfzm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define S(x,y,z) smoothstep(x,y,z)
#define PI (3.1415)
#define PIH (PI/2.0)

// https://stackoverflow.com/questions/15095909/from-rgb-to-hsv-in-opengl-glsl
// All components are in the range [0…1], including hue.
vec3 hsv2rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

float rand(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

vec2 rotate(vec2 uv, float angle)
{
    uv -= 0.5;
    mat2 mat = mat2(vec2(cos(angle), sin(angle)),vec2(-sin(angle), cos(angle)));
    return mat*uv + 0.5;
}

vec3 sphere_uv(vec2 uv, float time)
{
    
    uv = rotate(uv,0.2*sin(time));
    
    float factor = 1.3+0.5*sin(time);
    float dist = factor*sqrt(abs(1.0-dot(0.3*factor*uv,uv)));
    return vec3(time + uv*exp(dist),0.05 + dist*0.95);
}

float tileMask(vec2 uv, vec2 id)
{
    float r = rand(id);
    
    r = mod(floor(r*10.0),2.0);
    uv = rotate(uv,PIH*r);
    
    float lr = 0.545; // Line radius
       float lt = 0.1; // Line thickness
    float lb = 0.01; // line burr
    
    float d = length(uv-vec2(0.0,1.0));
    float m = S(lr+lb,lr,d);
    m -= S(lr-lt+lb,lr-lt,d);
    m = clamp(m,0.0,1.0);
      d = length(uv-vec2(1.0,0.0));
    m += S(lr+lb,lr,d);
    m -= S(lr-lt+lb,lr-lt,d);
    m = clamp(m,0.0,1.0);
    
    return m;
}

vec4 mn()
{
    vec2 uv = 2.0*gl_FragCoord.xy/resolution.xy-1.0;
    uv.x *= (resolution.x / resolution.y);
    
    vec2 suv = uv; // screen uv
    
    vec3 sphereRet = sphere_uv(uv,time/8.0);
    uv = sphereRet.xy;
    float aaFade = sphereRet.z; // Anti aliasing fade
    
    uv *= 5.0;
    vec2 id = floor(uv);
    uv = fract(uv);
    
    vec3 trailColorHSV = vec3(0.4*suv.x*suv.y + (1.0+sin(time))/2.0,0.8,0.7);
    
    vec3 col = vec3(tileMask(uv,id)) * hsv2rgb(trailColorHSV) * aaFade;
    
    return vec4(col,1.0);
}

void main(void)
{
    glFragColor = vec4(0.);
    int a = 4;
    for(int i1 = 0;i1<a;i1++){
        for(int i2 = 0;i2<a;i2++){
            glFragColor += mn();
        }
    }
    glFragColor /= float(a*a);
}

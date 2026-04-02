#version 420

// original https://www.shadertoy.com/view/7lGfWt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Funky Motherboard Carpet
//
// What's actually happens when pixels meet, hardwary speaking

mat2 rot(float a) { float c = cos(a), s = sin(a); return mat2(c,-s,s,c); }

// Dave Hoskins https://www.shadertoy.com/view/4djSRW
float hash13(vec3 p3)
{
    p3  = fract(p3 * .1031);
  p3 += dot(p3, p3.zyx + 31.32);
  return fract((p3.x + p3.y) * p3.z);
}

vec3 hash31(float p)
{
   vec3 p3 = fract(vec3(p) * vec3(.1031, .1030, .0973));
   p3 += dot(p3, p3.yzx+33.33);
   return fract((p3.xxy+p3.yzz)*p3.zyx); 
}

void main(void)
{
    vec3 color = vec3(0);
    
    // coordinates
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    vec2 p = 2.*(gl_FragCoord.xy*2.-resolution.xy)/resolution.y;
    
    // common parameters
    float thin = .1;
    float glow = .01;
    float delay = 10.;
    
    // grid
    float cell = 4.0;
    vec2 pp = floor(uv*cell)/cell;

    // random seed per cell grid
    float seed = hash13(vec3(pp, floor(time/delay))) * 196.;
    
    // random parameters per cell grid
    vec3 rng = hash31(seed);
    vec3 rng2 = hash31(seed+1096.);
    float size = mix(.01, .2, rng2.z);
    vec2 range = mix(vec2(.2), vec2(.8), rng.xy);
    float rangeY = mix(.1, .2, rng.z);
    float fallOff = mix(1.1, 1.2, rng2.x);
    float count = floor(mix(4., 12., rng2.y));
    
    // kaleidoscop
    float a = 1.0;
    for (float index = 0.; index < count; ++index)
    {
        // transform
        p = abs(p)-range*a;
        p *= rot(3.1415/4.);
        p.y = abs(p.y)-rangeY;
        
        // shape
        float dist = max(abs(p.x) + a*sin(6.28*index/count), p.y-size);
        
        // shade
        color += smoothstep(thin, 0.0, dist) * glow / dist;
        
        a /= fallOff;
    }
    
    color = clamp(color, 0., 1.);
    
    // palette
    color *= .5 + .5 * cos(vec3(1,2,3)*5. + p.x * 10.);
    
    // glow
    color += .04/abs(sin(p.y*12.+time*1.));

    glFragColor = vec4(color,1.0);
}

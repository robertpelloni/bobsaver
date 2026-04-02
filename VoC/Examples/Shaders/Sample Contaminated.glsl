#version 420

// original https://www.shadertoy.com/view/wsfcz8

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define S(a,b,x) smoothstep((a),(b),(x))
#define SMOOTH 0.01
#define blend(a, b, x) mix((a),(b),(x))

// Hash by Dave Hoskins
// https://www.shadertoy.com/view/4djSRW
//----------------------------------------------------------------------------------------
float hash12(vec2 p)
{
    vec3 p3  = fract(vec3(p.xyx) * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

float value_noise(vec2 uv)
{
    vec2    ID = floor(uv);
    // cell coord
    vec2 cc = fract(uv);

    float n1, n2, n3, n4, n12, n34;
    
    n1 = hash12(ID);
    n2 = hash12(ID + vec2(1, 0));
    n3 = hash12(ID + vec2(0, 1));
    n4 = hash12(ID + vec2(1, 1));
   
    n12 = (blend(n1, n2, cc.x));
    n34 = (blend(n3, n4, cc.x));
    
    return (blend(n12, n34, cc.y));
}

float oct_value_noise(float levels, float roughness, float descale, vec2 uv)
{
    float n = 0.,
        scale = 1.; 
    float final_divisor =0.;
    for(float i = 0.; i < levels; i++)
    {
        float octave_intensity = mix(1./(i+1.), 1., roughness);
        final_divisor += octave_intensity;
        n+= value_noise(uv * scale) * octave_intensity;
        scale *= descale;
        uv += vec2(7., 7.);
    }
    return n/final_divisor;
}

float sphere(vec2 pos, float r, vec2 uv)
{
    return length(uv - pos) -r;
}

float ring(vec2 pos, float r, vec2 uv)
{
    return abs(sphere(pos, r, uv));
}

float box(vec2 lw,  vec2 uv )
{
    vec2 d = abs(uv)-lw;
    return length(max(d,0.0)) + min(max(d.x,d.y),0.0);
}

vec2 rot(vec2 pos, float angle, vec2 uv)
{
    uv -= pos; 
    uv = vec2(uv.x * cos(angle) - uv.y * sin(angle) , uv.x * sin(angle) + uv.y * cos(angle));
    return uv + pos;
}

float biohazard(vec2 pos, float size, vec2 uv)
{
    uv *= size;
    uv = rot(vec2(0), float(frames)/180., uv);
    float val = 0.;
    float ring_punchout = 0.;
    float ring_w;
    // Doing the first part of the Symbol
    for(float i = 0.; i<3. ; i++)
    {
        float th_rad = .5;
        float dist = 0.;
        float angle = 3.1415/1.5 * i;
        vec2 uv_tmp = rot(vec2(0., -th_rad), angle, uv - vec2(0.0, 0.5));
        val = max(S(SMOOTH, 0.0, sphere(vec2(0.0), th_rad , uv_tmp)), val);
        val -= S(SMOOTH, 0.0, sphere(vec2(0.0, 0.11), .39, uv_tmp));
        // center of 2nd sphere, but smaller
        dist = ring(vec2(0.0, 0.11), th_rad - .125 , uv_tmp) ;
        
        float ring_w = 0.022;
        ring_punchout = max(S(SMOOTH+ring_w, ring_w, dist), ring_punchout);
        
        uv_tmp = rot(vec2(0., -th_rad), angle, uv - vec2(0.0, 0.5)) + vec2(0, 0.34); //UV for box
        val = min(S(0., SMOOTH,  ( box(vec2(0.023, 0.06), uv_tmp)) ), val); // BOX

    }
    // the punchout ring
    ring_w = 0.04;
    
    val = max(val,S(SMOOTH + ring_w, ring_w,   ring(vec2(0), .4, uv)));
    val -= ring_punchout;
    
    
    val -= S(SMOOTH, 0.0, sphere(vec2(0), 0.11, uv));
    
    return val;
}

void main(void)
{
    // Centered pixel coordinates (from 0 to 1)
    vec2 uv = ((gl_FragCoord.xy/resolution.xy)-.5)*2., uv_vignette = uv;
    
    uv.x *= resolution.x/resolution.y;
    
    // draw symbol
    float val = clamp(biohazard(vec2(0), 1., uv), 0., 1.);
    
    // dirt
    float n = oct_value_noise(8., 1., 1.6, uv*7. * vec2(1.5, .6));
    n = S(value_noise((uv + vec2(45., 67.))* vec2(10, 4))*.6,
          value_noise((uv + vec2(145., 167.))*9.)*.7+.4, n);
  
    vec4 bg = mix(vec4(.9, .9, .2, 0), vec4(0.8, 0.75, 0.14,0),1.- n);
    float v = value_noise((uv + vec2(45., 67.))* vec2(320, 320));
    // Output to screen               *    Vignette
    glFragColor = bg*vec4(1.-val) * (1.-pow(length(uv_vignette*.6), v*3.+1.2));
  
}

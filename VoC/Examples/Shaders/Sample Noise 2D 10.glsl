#version 420

// original shadertoy.com/view/3sXcRj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*  
    This is my take on making an FBM noise that is more interesting by adding some
    variation to it. This makes it more uneven and gets rid of the cloudy look which
    is nice, but not always desired. Instead, I am adding variation to the intensities
    of the gradients using a pow-function.

    Mouse-x: Octaves of noise
    Mouse-y: Power of variation of intensities

    Left view:  The output of the noise function
    Right view: Smoothstepping the output to extract a range

    NOTES:
    > The right side of the view applies a simple boxfiltered antialiasing which you can
      basically turn off by setting BOXFILTER_SAMPLES to 1.0
    > The gradient of the noise is being animated with time, so you get a morphing
      effect of the which I found interesting.

    CHECK OUT
    *********

    Vanilla FBM explorer:        https://www.shadertoy.com/view/tdlyz4
    Noise -gradient 2d by IQ:    https://www.shadertoy.com/view/XdXGW8

*/

#define DO_ROTATE         true  
#define BOXFILTER_SAMPLES 2.0
#define PI                3.14159265359

// Hashes by Dave Hoskins
// https://www.shadertoy.com/view/4djSRW
//----------------------------------------------------------------------------------------
///  2 out, 2 in...
vec2 hash22(vec2 p)
{

    vec3 p3 = fract(vec3(p.xyx) * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yzx+33.33);
    return fract((p3.xx+p3.yz)*p3.zy);
}

float gainf(float x, float k) 
{
    //remap k, so k is driven by 0...1 range
    k = k < 0.5 ? 2.*k : 1./(1.-(k-0.5)*2.);
    float a = 0.5*pow(2.0*((x<0.5)?x:1.0-x), k);
    return (x<0.5)?a:1.0-a;
}

// performs a golden-ratio rotation
vec2 rot_golden(vec2 pos,vec2 uv)
{
    // golden/ration in radians: 3.883222072739204862525004958380
    float sine   = -0.67549029078724183023998;
    float cosine = -0.73736888126104662389070;
    mat2 rot = mat2(cosine, -sine, sine, cosine);
    uv -= pos; 
    uv = rot * uv  ;
    return uv + pos;
}

float gradnoise_random(vec2 uv)
{
    vec2 p = floor(uv),
        f = (fract(uv));
    
    vec2 u = f*f*f*(6.0*f*f - 15.0*f +10.0);  // from Ken Perlin's improved noise
    //vec2 u = f*f*(3.-2.*f);                 // simpler formula (s-curve)
    float dot1, dot2, dot3, dot4;
    
    dot1 = dot(2.*(hash22(p)) - 1.0, f);
    dot2 = dot(2.*(hash22(p + vec2(1., 0.)))-1.0 , f - vec2(1.,0.));
    dot3 = dot(2.*(hash22(p + vec2(0., 1.)))-1.0, f - vec2(0.,1.));
    dot4 = dot(2.*(hash22(p + vec2(1., 1.)))-1.0, f - vec2(1.,1.));
   
    float m1, m2;
    
    m1 = mix(dot1, dot2, u.x);
    m2 = mix(dot3, dot4, u.x);
    
    return mix(m1, m2, u.y);
}

// This gradient noise makes sure gradients lie on the unit-circle and it 
float gradnoise_circular(vec2 uv, float power)
{
    vec2 p = floor(uv),
        f = (fract(uv));
    
    vec2 u = f*f*f*(6.0*f*f - 15.0*f +10.0);
    //vec2 u = f*f*(3.-2.*f);
    float dot1, dot2, dot3, dot4;
    
    vec2 hash00, hash10, hash01, hash11;
    vec2 grad00, grad10, grad01, grad11;
  
    hash00 = hash22(p);
    hash01 = hash22(p + vec2(0., 1.));
    hash10 = hash22(p + vec2(1., 0.));
    hash11 = hash22(p + vec2(1., 1.));

    // Calculate gradients. The sin and cos part makes sure that the gradient vectors are
    // unit length. Since the hash values range from 0...1 we need to bring them in the
    // range of 2 PI which describes a whole circle, so gradient vectors point in any
    // possible direction.
    // The pow function at the end is what makes the intensities of the gradients more
    // uneven, so we get a more irregular pattern of the noise. If the 'power' value gets 
    // too high, the noise starts looking bad though.
    // One could
     //Gradients shall lie on the unit circle
    grad00 = vec2(sin(hash00.x * PI * 2. + time), cos(hash00.x * PI * 2. + time)) * (pow(hash00.y, power));
    grad01 = vec2(sin(hash01.x * PI * 2. + time), cos(hash01.x * PI * 2. + time)) * (pow(hash01.y, power));
    grad10 = vec2(sin(hash10.x * PI * 2. + time), cos(hash10.x * PI * 2. + time)) * (pow(hash10.y, power));
    grad11 = vec2(sin(hash11.x * PI * 2. + time), cos(hash11.x * PI * 2. + time)) * (pow(hash11.y, power));
    
    dot1 = dot(grad00, f);
    dot2 = dot(grad10, f - vec2(1.,0.));
    dot3 = dot(grad01, f - vec2(0.,1.));
    dot4 = dot(grad11, f - vec2(1.,1.));
  
 /*   Classic approach
    dot1 = dot((hash22(p)), f);
    dot2 = dot((hash22(p + vec2(1., 0.))) , f - vec2(1.,0.));
    dot3 = dot((hash22(p + vec2(0., 1.))) , f - vec2(0.,1.));
    dot4 = dot((hash22(p + vec2(1., 1.))) , f - vec2(1.,1.));
*/    
    float m1, m2;
    
    m1 = mix(dot1, dot2, u.x);
    m2 = mix(dot3, dot4, u.x);
   
   // return abs(box_mueller_transform(hash00)).x;
    return mix(m1, m2, u.y);
}

vec2 calc_pos_width(float pos, float width)
{
    float low, high;
    
    low = pos - width/2.0;
    high = pos + width/2.0;
    return clamp(vec2(low, high), vec2(0.0), vec2(1.0));
}

float oct_gained_gradnoise(vec2 uv, float octaves, float roughness, float octscale, float power)
{
    float a = 0.;
    float intensity = 1.;
    float oct_intensity = 1.0; // first intensity is 1.0, successive octaves get scaled by roughness value
    float total_scale = 0.0;
    float remap;

    float contrast = 0.999;
    float gain = .00111;

    for(float i = 0.; i < octaves; i++)
    {
        float gradnoise_lookup = gradnoise_circular(uv, power)*1.75;
        
        remap = gradnoise_lookup;
        remap = gainf((gradnoise_lookup*.5 + .5), gain);
       // remap = gainf(clamp((gradnoise_lookup*.5 + .5), 0.0, 1.0), gain);
        remap = ((remap - 0.5) * 2.); 
        
        total_scale += oct_intensity;
        a += remap* oct_intensity;
        oct_intensity*= roughness; // get intensity for current octave
        
        if(DO_ROTATE)
            uv = rot_golden(vec2(11.1231, 11.1231), uv) * octscale;
        else
            uv = uv * octscale;
    }
    // applying contrast and clamping it
    
    a = (a/(1.0 -contrast)) ;
    a= clamp(a/total_scale, -1., 1.0);
    return a; // if we were dividing just by octaves we'd get an intensity shift
}

void main(void)
{
    vec2 uvMouse;
    
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv.x *= resolution.x/resolution.y;
    uv.x += time*.1;
    
    // check for out of range coords (which happens at the start or after
    // change of resolution)
    if (mouse*resolution.xy.xy==vec2(0) )
        uvMouse = vec2(0.75, 0.5);
    else
        uvMouse = (mouse*resolution.xy.xy/resolution.xy);
        
    //if(int(mouse*resolution.xy.xy) == 0 || mouse*resolution.xy.x > resolution.x || mouse*resolution.xy.y > resolution.y)
    //    uvMouse = vec2(0.75, 0.5);
    //else
    //    uvMouse = (mouse*resolution.xy.xy/resolution.xy);
     

    int octaves = int(ceil(uvMouse.x * 10.));
    float power = uvMouse.y * 6.+.1;
    float roughness = 1.1; //uvMouse.y*1.5;
    
    
    // Static gradnoise
    float octscale = 2.0; //factor by which each octave gets smaller than the previous one
    float final_value;
    
    final_value = oct_gained_gradnoise(uv * 2., float(octaves), roughness, octscale, power);
    
    
    //antialiasing
    /*
    float acc = 0.;
    for(float i = 0.; i < AA; i++)
        for(float j = 0.; j < AA; j++)
        {
            acc += oct_gained_gradnoise((uv + vec2(i*step_size.x, j*step_size.y)) * 2., float(octaves), roughness, octscale);
         }
    acc /= AA*AA ;    
*/
   // final_value = acc;
    final_value = final_value*0.5 + 0.5;
    
    
    
    if(gl_FragCoord.xy.x > resolution.x/2.)
    {
        vec2 low_high = calc_pos_width(sin(time * .5)*.3 + .3, sin(time*.43321578)*.35 + .4);
        
        //antialiasing  
           float AA = BOXFILTER_SAMPLES;
        vec2 pixel_size = vec2(1.)/resolution.xy;
        vec2 step_size = pixel_size/AA * 1.5;
        float acc = 0.;
        float lookup = 0.0;
        for(float i = 0.; i < AA; i++)
            for(float j = 0.; j < AA; j++)
            {
                lookup = oct_gained_gradnoise((uv + vec2(i*step_size.x, j*step_size.y)) * 2., float(octaves), roughness, octscale, power);
                acc += smoothstep(low_high.x, low_high.y, lookup);
             }
        acc /= AA*AA ;    
        final_value = acc;
        
        
       
    }

  
    if(mod(gl_FragCoord.xy.x, resolution.x /2.) < 1.)
        final_value = 0.;

    glFragColor = vec4(final_value);
}

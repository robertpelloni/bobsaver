#version 420

// original https://www.shadertoy.com/view/tl3GR8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float TonemapFloat( float x )
{
    return 1.0f - exp( -x ); // can change the tonemap function here 
}

vec3 TonemapFloat3( vec3 x )
{
    vec3 r;
    r.x = TonemapFloat( x.x );
    r.y = TonemapFloat( x.y );
    r.z = TonemapFloat( x.z );
    
    return r;
}

vec3 whitePreservingLumaBasedReinhardToneMapping(vec3 color)
{
    float white = 2.;
    float luma = dot(color, vec3(0.2126, 0.7152, 0.0722));
    float toneMappedLuma = luma * (1. + luma / (white*white)) / (1. + luma);
    color *= toneMappedLuma / luma;
//    color = pow(color, vec3(1. / 2.2));
    return color;
}

float GetBT709Luminance( vec3 c )
{
    return dot( c, vec3(0.2126f, 0.7152f, 0.0722f) );
}

vec3 TonemapProcess( vec3 c )
{
    float YOrig = GetBT709Luminance( c );
    
    // Sort of hue preserving tonemap by scaling the original color by the original and tonempped luminance
    float YNew = GetBT709Luminance( whitePreservingLumaBasedReinhardToneMapping( c ) );
    vec3 result = c * YNew / YOrig;
    
    float desaturated = GetBT709Luminance( result );
        
    // Stylistic desaturate based on luminance - we want pure primary red to desaturate _slightly_ when bright
    float sdrDesaturateSpeed = 0.2f;
    float stylisticDesaturate = TonemapFloat( YOrig * sdrDesaturateSpeed );
    
    
    float stylisticDesaturateScale = 0.8f; // never fully desaturate bright colors
    stylisticDesaturate *= stylisticDesaturateScale;    
    
    result = mix( result, vec3(desaturated), stylisticDesaturate );
    
    return result;
}

vec3 hsv2rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

float smootherstep(float edge0, float edge1, float x)
{
    x = clamp((x - edge0)/(edge1 - edge0), 0.0, 1.0);
    return x*x*x*(x*(x*6.0 - 15.0) + 10.0);
}

vec3 adjust_out_of_gamut_maxcomp(vec3 c)
{
    const float BEGIN_SPILL = 1.0;
    const float END_SPILL = 4.0;
    const float MAX_SPILL = 0.9; //note: <=1
    
    float mc = max(c.r, max(c.g, c.b));
    float t = MAX_SPILL * smootherstep( 0.0, END_SPILL-BEGIN_SPILL, mc-BEGIN_SPILL );
    return mix( c, vec3(mc), t);
}

const vec3 LumWeights = vec3(0.2126, 0.7152, 0.0722);

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;

    vec3 c = hsv2rgb(vec3(uv.x,1.,1.0));
    float lum = dot(c, LumWeights);
    c = c * (pow(uv.y,2.)/lum * 8.);
    
    int x = int(floor(fract(uv.x/6.+time/8.) * 8.));
    //x=7;
    
    switch (x)
    {
       // No tonemap, no gamma
       case 0: break;   
       // Luminance of no tonemap no gamma
       case 1: 
                   c = clamp(c,0.,1.);
                lum = dot(c, LumWeights);
                c = vec3(lum);
                break;
        // Tonemap and gamma
        case 2:
                c = whitePreservingLumaBasedReinhardToneMapping(c);
                c = pow(c, vec3(1. / 2.2));
                c = clamp(c,0.,1.);
                break;
        // Luminance tonemap and gamma
        case 3:
                c = whitePreservingLumaBasedReinhardToneMapping(c);
                c = pow(c, vec3(1. / 2.2));
                c = clamp(c,0.,1.);
                lum = dot(c, LumWeights);
                c = vec3(lum);
                break;
        // Paul Malin's method 
        //https://twitter.com/Bananaft/status/1202358736238587906
        //https://www.shadertoy.com/view/ls2fRt
        //https://www.shadertoy.com/view/wld3zn
        case 4:
                c = TonemapProcess(c);
                c = pow(c, vec3(1. / 2.2));
                c = clamp(c,0.,1.);
                break;
        // Luminance of Paul Malin's method 
        case 5:
                c = TonemapProcess(c);
                c = pow(c, vec3(1. / 2.2));
                c = clamp(c,0.,1.);
                lum = dot(c, LumWeights);
                c = vec3(lum);
                break;
        
        // Mikkel Gjoel's
        //https://twitter.com/pixelmager/status/1202525285498920961
        //https://www.shadertoy.com/view/3ldGRn
        case 6:
                c = whitePreservingLumaBasedReinhardToneMapping(c);
                c = adjust_out_of_gamut_maxcomp(c);
                c = pow(c, vec3(1. / 2.2));
                c = clamp(c,0.,1.);
                break;
        
        // Luminance of Mikkel Gjoel's
        case 7:
                c = whitePreservingLumaBasedReinhardToneMapping(c);
                c = adjust_out_of_gamut_maxcomp(c);
                c = pow(c, vec3(1. / 2.2));
                c = clamp(c,0.,1.);
                lum = dot(c, LumWeights);
                c = vec3(lum);
                break;

    }
    glFragColor = vec4(c,1.0);
}

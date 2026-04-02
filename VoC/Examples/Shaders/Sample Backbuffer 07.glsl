#version 420

//optical feedback experiment

uniform float time;
uniform vec2 resolution;
uniform sampler2D backbuffer;

out vec4 glFragColor;

#define K (1.0/6.0)

vec3 rgbFromHue(float h) {
    
    h = h - floor(h);
    
    float r = smoothstep( 2.0*K, 1.3*K, h) + smoothstep( 4.0*K, 5.0*K, h);
    float g = smoothstep( 0.0*K, 1.0*K, h) - smoothstep( 3.0*K, 4.0*K, h);
    float b = smoothstep( 2.0*K, 3.0*K, h) - smoothstep( 5.0*K, 6.0*K, h);
    
    return vec3(r,g,b);
}

/*
** Contrast, saturation, brightness
** Code of this function is from TGM's shader pack
** http://irrlicht.sourceforge.net/phpBB2/viewtopic.php?t=21057
*/

// For all settings: 1.0 = 100% 0.5=50% 1.5 = 150%
vec3 ContrastSaturationBrightness(vec3 color, float brt, float sat, float con)
{
    // Increase or decrease theese values to adjust r, g and b color channels seperately
    const float AvgLumR = 0.5;
    const float AvgLumG = 0.5;
    const float AvgLumB = 0.5;
    
    const vec3 LumCoeff = vec3(0.2125, 0.7154, 0.0721);
    
    vec3 AvgLumin = vec3(AvgLumR, AvgLumG, AvgLumB);
    vec3 brtColor = color * brt;
    vec3 intensity = vec3(dot(brtColor, LumCoeff));
    vec3 satColor = mix(intensity, brtColor, sat);
    vec3 conColor = mix(AvgLumin, satColor, con);
    return conColor;
}

vec3 RGBToHSL(vec3 color)
{
    vec3 hsl; // init to 0 to avoid warnings ? (and reverse if + remove first part)
    
    float fmin = min(min(color.r, color.g), color.b);    //Min. value of RGB
    float fmax = max(max(color.r, color.g), color.b);    //Max. value of RGB
    float delta = fmax - fmin;             //Delta RGB value

    hsl.z = (fmax + fmin) / 2.0; // Luminance

    if (delta == 0.0)        //This is a gray, no chroma...
    {
        hsl.x = 0.0;    // Hue
        hsl.y = 0.0;    // Saturation
    }
    else                                    //Chromatic data...
    {
        if (hsl.z < 0.5)
            hsl.y = delta / (fmax + fmin); // Saturation
        else
            hsl.y = delta / (2.0 - fmax - fmin); // Saturation
        
        float deltaR = (((fmax - color.r) / 6.0) + (delta / 2.0)) / delta;
        float deltaG = (((fmax - color.g) / 6.0) + (delta / 2.0)) / delta;
        float deltaB = (((fmax - color.b) / 6.0) + (delta / 2.0)) / delta;

        if (color.r == fmax )
            hsl.x = deltaB - deltaG; // Hue
        else if (color.g == fmax)
            hsl.x = (1.0 / 3.0) + deltaR - deltaB; // Hue
        else if (color.b == fmax)
            hsl.x = (2.0 / 3.0) + deltaG - deltaR; // Hue

        if (hsl.x < 0.0)
            hsl.x += 1.0; // Hue
        else if (hsl.x > 1.0)
            hsl.x -= 1.0; // Hue
    }

    return hsl;
}

float HueToRGB(float f1, float f2, float hue)
{
    if (hue < 0.0)
        hue += 1.0;
    else if (hue > 1.0)
        hue -= 1.0;
    float res;
    if ((6.0 * hue) < 1.0)
        res = f1 + (f2 - f1) * 6.0 * hue;
    else if ((2.0 * hue) < 1.0)
        res = f2;
    else if ((3.0 * hue) < 2.0)
        res = f1 + (f2 - f1) * ((2.0 / 3.0) - hue) * 6.0;
    else
        res = f1;
    return res;
}

vec3 HSLToRGB(vec3 hsl)
{
    vec3 rgb;
    
    if (hsl.y == 0.0)
        rgb = vec3(hsl.z); // Luminance
    else
    {
        float f2;
        
        if (hsl.z < 0.5)
            f2 = hsl.z * (1.0 + hsl.y);
        else
            f2 = (hsl.z + hsl.y) - (hsl.y * hsl.z);
            
        float f1 = 2.0 * hsl.z - f2;
        
        rgb.r = HueToRGB(f1, f2, hsl.x + (1.0/3.0));
        rgb.g = HueToRGB(f1, f2, hsl.x);
        rgb.b= HueToRGB(f1, f2, hsl.x - (1.0/3.0));
    }
    
    return rgb;
}

#define N 5.0
void main( void ) {

    float acc = 0.0;
    
    // Screen rectangle centered in quad (1.0,1.0,-1.0,-1.0);
    vec2 pos = 2.0 * ( gl_FragCoord.xy / resolution.xy ) + vec2(-1.0,-1.0);
    
    // Adjust Screen ratio
    pos *= vec2(resolution.x/resolution.y, 1.0);
    
    float r1=0.5;
    
    const float n = 8.0;
    const float ph = 3.14156492 * 2.0 / n;
        
    float cph = .0;
    float rm = 0.2;
    
    for (float i=0.0; i<n; i++) {
        
        cph += ph;
        rm = -rm;
        
        vec2 posS0 = vec2(sin(time+cph), cos(time+cph))*(r1+rm*sin(time*3.0));
        vec2 posS1 = vec2(sin(time*10.0+cph), cos(time*10.0+cph))*r1*0.35;
    
        acc += smoothstep(0.05,0.,distance(pos,posS0+posS1));
        acc += smoothstep(0.05,0.,distance(pos,posS0));
    }
    
    
    vec3 color;
    
    const float sr = 10.0;
    
    color =( texture2D(backbuffer, gl_FragCoord.xy/resolution).rgb +
         texture2D(backbuffer, vec2(gl_FragCoord.x-sr*pos.x * .5, gl_FragCoord.y)/resolution).rgb +
         texture2D(backbuffer, vec2(gl_FragCoord.x-sr*pos.x, gl_FragCoord.y)/resolution).rgb +
         texture2D(backbuffer, vec2(gl_FragCoord.x, gl_FragCoord.y-sr*pos.y *.5)/resolution).rgb +
         texture2D(backbuffer, vec2(gl_FragCoord.x, gl_FragCoord.y-sr*pos.y)/resolution).rgb)*0.2;
    
    color=ContrastSaturationBrightness(color,0.7,2.5,1.0);
    vec3 HueSatL=RGBToHSL(color);
    HueSatL.x=HueSatL.x+0.05;
    color=HSLToRGB(HueSatL);
    
    glFragColor = vec4( clamp(acc,.0,1.0) * rgbFromHue( cos(pos.x+time)+sin(pos.y+time*1.013)*0.5) + color*0.975, 1.0 );
}

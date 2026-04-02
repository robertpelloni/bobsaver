#version 420

// original https://www.shadertoy.com/view/3tByDm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Adpated from: https://www.shadertoy.com/view/Xsl3WH by Nikos Papadopoulos, 4rknova / 2013
// WTFPL

#define A .4 // Amplitude
#define V 9. // Velocity
#define W 16. // Wavelength
#define T .001 // Thickness
#define S 1. // Sharpness
#define Abba 0.000 // aberation
int Str = 12; // String Amount
float O1;
float sine(vec2 p, float o, float w)
{
    float nw = abs(sin(time*0.9)*8.0);
    float nw2 = (sin(time*0.08)*0.125);
    return pow(T / abs((p.y + sin((p.x * nw+w + o)) * A*nw2)), S);
}

void main(void)
{
    vec2 p = gl_FragCoord.xy / resolution.xy * 1. - 1.;
    vec3 s = vec3(0.0);
    
    for (int i = 0; i < Str; i++)
    {
        float sh = (1.0/float(Str))/2.0;
        float sep = (1.0/float(Str)) * float(i);
        
        vec2 pos = vec2(p.x,p.y) + (sep+sh);
       // s -= vec3(sine(pos, (time * V)*O1,W*O1-float(i)  ));
        s.x += vec3(sine(pos-Abba, (time * V),W-float(i) )).x;
        s.y += vec3(sine(pos, (time * V),W-float(i) )).y;
        s.z += vec3(sine(pos+Abba, (time * V),W-float(i) )).z;
    }  
    glFragColor = vec4(s, 1);
}

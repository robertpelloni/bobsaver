#version 420

/*
    Texture Slurring
    2015 BeyondTheStatic
    Move mouse to lower left corner to reset texture.

    Gooey Smooth version: mostly mixes everything down to gray but oh well :P
    Adding contrast and brightness helps a bit
*/
#define SlurAmt     7.0
#define SlurFreq    0.5
#define TimeFreq    0.333

#define PI2 6.28318530717958

float rand(vec2 p){ return fract(sin(dot(p, vec2(12.9898, 78.233)))*43758.5453); }

uniform sampler2D backbuffer;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec4 texture2D_bicubic(sampler2D tex, vec2 uv)
{
    vec2 ps = 1./resolution;
    vec2 uva = uv+ps*.5;
    vec2 f = fract(uva*resolution);
    vec2 texel = uv-f*ps;
#define bcfilt(a) (a<2.?a<1.?((3.*a-6.)*a*a+4.)/6.:(((6.-a)*a-12.)*a+8.)/6.:0.) 
    vec4 fxs = vec4(bcfilt(abs(1.+f.x)), bcfilt(abs(f.x)),
            bcfilt(abs(1.-f.x)), bcfilt(abs(2.-f.x)));
    vec4 fys = vec4(bcfilt(abs(1.+f.y)), bcfilt(abs(f.y)),
            bcfilt(abs(1.-f.y)), bcfilt(abs(2.-f.y)));
#undef bcfilt
    vec4 result = vec4(0);
    for (int r = -1; r <= 2; ++r)
    {
        vec4 tmp = vec4(0);
        for (int t = -1; t <= 2; ++t)
            tmp += texture2D(tex, texel+vec2(t,r)*ps) * fxs[t+1];
        result += tmp * fys[r+1];
    }
    return result;
}

void main( void ) {
    vec2 res = resolution.xy;
    vec2 uv  = gl_FragCoord.xy;
    vec2 uvb = uv / res;
    vec2 mpos = mouse * res;
    
    vec3 RGB;
    if(time<=1.0 || max(mpos.x, mpos.y)<32.) // initial RGB values for texture buffer
    {
        float circ = length(uvb-.5);
        RGB = vec3(.5) + .5 * vec3(cos(3.*PI2*circ), cos(4.*PI2*circ), cos(5.*PI2*circ));
        RGB *= 2. - 3. * circ;
    }
    else // slur texture buffer        
    {
        float X = mod(uv.x+SlurAmt*sin(uvb.y*PI2*SlurFreq+time*PI2*TimeFreq), res.x)/res.x;
        float Y = mod(uv.y+SlurAmt*cos(uvb.x*PI2*SlurFreq+time*PI2*TimeFreq), res.y)/res.y;
        RGB = texture2D_bicubic(backbuffer, vec2(X, Y)).rgb;
        //add some contrast
        float r=RGB.r;
        float g=RGB.g;
        float b=RGB.b;
        float amount=0.5; //20% contrast
        r=r+(r-0.5)*amount/100.0;
        g=g+(g-0.5)*amount/100.0;
        b=b+(b-0.5)*amount/100.0;
        //bit of brightness for darker pixels
        if (r+g+b<1.3) 
      {
            r=r+0.001;
            g=g+0.001;
            b=b+0.001;
        }
        RGB=vec3(r,g,b);
    }    
    glFragColor = vec4(RGB, 1.);
}

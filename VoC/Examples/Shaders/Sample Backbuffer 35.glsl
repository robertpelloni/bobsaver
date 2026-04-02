#version 420

/*
    Texture Slurring
    2015 BeyondTheStatic
    Move mouse to lower left corner to reset texture.
*/
#define SlurAmt        7.0
#define SlurFreq    0.5
#define TimeFreq    0.333

#define PI2 6.28318530717958

float rand(vec2 p){ return fract(sin(dot(p, vec2(12.9898, 78.233)))*43758.5453); }

uniform sampler2D backbuffer;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

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
        RGB = texture2D(backbuffer, vec2(X, Y)).rgb;
    }    
    glFragColor = vec4(RGB, 1.);
}

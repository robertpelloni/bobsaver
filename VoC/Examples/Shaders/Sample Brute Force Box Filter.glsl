#version 420

// original https://www.shadertoy.com/view/tlffzS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Brute Force Box Filter - Each pixel is super sampled 256 times!
// If you know about implementing a Gausian filter in Shadertoy, please help!

void main(void)
{
    vec4 O=glFragColor;
    O-=O;
    vec2 R = resolution.xy, u, a = (gl_FragCoord.xy - .5*R)/R.y;
        
    float A = 16.,   //The A variable determines the level of Anti-Aliasing
          s = 1./A,
          w = s*s,
          t = .3 * time,
          x, y;
    
        for (y=0.; y < 1.; y += s)
            for (x=0.; x < 1.; x += s)
                u = a + vec2(x,y)/R.y,
                u /= dot(u,u),
                O += max(u=fract(3.*u + t),u.x-u).y * w;

    glFragColor=O;
}

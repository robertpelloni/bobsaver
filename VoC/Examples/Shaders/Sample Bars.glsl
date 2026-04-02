#version 420

// bars - thygate@gmail.com

// rotation and color mix modifications by malc (mlashley@gmail.com)
// waves modified by @hintz 2013-05-01

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 position;

float c,s,barsangle;
mat2 R;

float barsize = 0.15;

vec4 bar(float pos, float r, float g, float b)
{
    //pos*=3.0;
    return max(0.0, 4.0-fract(pos - position.y + 0.5*sin(2.0*time+sin(1.0-pos*2.0)*4.0*position.x)) / barsize) * vec4(r, g, b, 1.0);
}

void main(void) 
{
    c = cos(time*0.5);
    s = sin(time*0.5);
    R = mat2(c,-s,s,c);
    barsangle = 200.0*sin(time*0.0001);

    position = (gl_FragCoord.xy - 0.5*resolution.xy) / resolution.xx;
    position = 1.5*position * R;         
        
    float t = time*0.05;

    vec4 color = bar(sin(t), 1.0, 0.0, 0.0);
    color += bar(sin(t+barsangle*2.), 1.0, 0.5, 0.0);
    color += bar(sin(t+barsangle*4.), 1.0, 1.0, 0.0);
    color += bar(sin(t+barsangle*6.), 0.0, 1.0, 0.0);
    color += bar(sin(t+barsangle*8.), 0.0, 1.0, 1.0);
    color += bar(sin(t+barsangle*10.), 0.0, 0.0, 1.0);
    color += bar(sin(t+barsangle*12.), 0.5, 0.0, 1.0);
    color += bar(sin(t+barsangle*14.), 1.0, 0.0, 1.0);
    
    glFragColor = 0.2+normalize(color);
}

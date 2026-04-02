#version 420

// Feedback fun by psonice.
// Needs a large window size to work

#define BPM 60.0
#define R(p,a) vec2(cos(a)*p.x+sin(a)*-p.y, cos(a)*p.y+sin(a)*p.x)

uniform sampler2D backbuffer;
uniform float time;
uniform vec2 resolution;

out vec4 glFragColor;
void main()
{
    float s = BPM/60.;
    vec2 c = gl_FragCoord.xy/resolution;
    c -= 0.5;
    
    // draw a circle
    float l = length((c-.5));
    float o = l < 0.02 ? 1. : 0.;
    o = abs(c.x) > 0.499 && abs(c.y) > 0.499 ? 1. : 0.;// abs(c.y) < 0.01 ? 1. : 0.;
    
    // add backbuffer with transform
    float t = mod(time*s, 3.142);
    c *= 1.+ sin(t)*0.02;
    c = R(c,sin(time*.2)*0.03);
    //c = pow(c, vec2(1.+sin(time)*.01)) * sign(c);
    c += vec2(
        sin(c.y*10.+time*0.55),
        sin(c.x*10.+time*0.34))*(sin(time*0.1)+1.1)*0.008;
    c.x += sin(c.x *20.+time)*sin(time*0.2)*0.01;
    c.x += sin(c.y *22.+time)*sin(time*0.1)*0.01;
    c = R(c, (.5-length(c))*0.0125);
    c += 0.5;
    float b = texture2D(backbuffer, c).r;
        
    // modulate value for B+W striping
    o += b;
    o = floor(o*8.+.5)/8.;
    o = mod(o, 2.);
    
    glFragColor = vec4(o);
}

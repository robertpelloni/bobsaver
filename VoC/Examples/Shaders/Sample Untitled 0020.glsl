#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;
uniform sampler2D backbuffer;

out vec4 glFragColor;

#define ASPECT resolution.x/resolution.y
#define PI 3.14159265

vec3 rgb2hsv(vec3 c)
{
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}
 

vec3 hsv2rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void main( void ) {
    
    vec2 pos = (gl_FragCoord.xy-resolution*0.5)/resolution*vec2(ASPECT,1.0)*(1.0 + sin(time));
    vec3 finalColor = vec3(0.0);
    float angle = sin(time*0.5)*PI;
    vec2 trans;
    trans.x = pos.x*cos(angle)-pos.y*sin(angle)+cos(time)*0.25;
    trans.y = pos.x*sin(angle)+pos.y*cos(angle)+sin(time)*0.25;
    if (abs(trans.y)<0.2 && abs(trans.x)<0.2 && trans.x<trans.y*sin(time))
        finalColor.r = 1.0-sin(time);
    vec3 bb = texture2D(backbuffer, gl_FragCoord.xy/resolution).rgb;
    vec3 hsvbb = rgb2hsv(bb);
    vec3 rotbb = hsv2rgb(hsvbb + vec3(0.01,0.,0.));
    glFragColor = vec4(finalColor*.4 + rotbb*0.95, 1.0);
}

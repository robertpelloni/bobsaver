#version 420

// original https://www.shadertoy.com/view/tslcD8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{   
    float speed = 1.;
    float scale = 0.002;
    vec2 p = (gl_FragCoord.xy/resolution.xy- vec2(0.5))*2.0;
    p.x *= resolution.x/resolution.y;
    p *= 0.5;
    p.x += time/2.;
    //vec2 p = gl_FragCoord.xy * scale;   
    for(int i=1; i<10; i++){
        p.x+=0.3/float(i)*sin(float(i)*3.*p.y+time*speed*1.);//+mouse*resolution.xy.x/1000.;
        p.y+=0.3/float(i)*cos(float(i)*3.*p.x+time*speed*1.);//+mouse*resolution.xy.y/1000.;
    }
    //p.xy += time*10.;
        
    float t = time*1.0;
    float gbOff = p.x;
    float gOff = 0.0+p.y;
    float rOff = 0.0;
    float r=cos(p.x+p.y+1.+rOff)*.5+.5;
    float g=sin(p.x+p.y+1.+gbOff+gOff)*.5+.5;
    float b=(sin(p.x+p.y+gbOff)+cos(p.x+p.y+gbOff))*.3+.5;
    vec3 color = vec3(r,g,b);
    //vec3 color = vec3(p.x,p.y,0.0);
    glFragColor = vec4(color,1);
}

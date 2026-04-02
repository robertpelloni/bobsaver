#version 420

// Two dancing Rings 2017-11-30 by @hintz

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{    
    float n = 0.5;
    vec2 p = 2.0*(gl_FragCoord.xy-0.5*resolution)/resolution.y;
    p = vec2(1.0+atan(p.y,p.x),length(p)-0.5);
    p = vec2(n*cos(p.x+0.1*time),p.y); 
    float y0 = p.y + 0.2*sin(p.x+time-1.0+0.5*cos(time));
    float y1 = p.y + 0.2*cos(p.x+time+1.0+0.5*sin(time));
    y0 *= y0;
    y1 *= y1;
    y0 = sqrt(1.0 - y0 * 100.0);
    y1 = sqrt(1.0 - y1 * 100.0);
    float y2 = cos(p.x+time-1.0+0.5*cos(time));
    float y3 = -sin(p.x+time+1.0+0.5*sin(time));
    float y = max(y0+y2,y1+y3);
    float c = y;
    vec3 color = c*normalize(vec3(c,p.x+c,c+p.y));
    glFragColor = vec4(color.zxy,1.0);
}

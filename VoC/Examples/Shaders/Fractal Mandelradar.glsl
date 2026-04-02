#version 420

// original https://www.shadertoy.com/view/Md23D3

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;

out vec4 glFragColor;

void main(void)
{
    vec2 c;
    c.x = -2.4 + 3.6 * gl_FragCoord.x / resolution.x;
    c.y = -1.4 + 2.8 * gl_FragCoord.y / resolution.y;
    
    float len = 0.0;
    vec2 curr = vec2(0.0,0.0);
    vec2 prev = curr;

    for(int i=0; i<64; i++){
        curr.x = prev.x*prev.x - prev.y*prev.y;
        curr.y = 2.0 * prev.x * prev.y;
        curr += c;
        
        vec2 tmp = curr - prev;
        len += sqrt(dot(tmp,tmp));

        if(dot(curr,curr) >= 4.0) break;
        
        prev = curr;
    }
    
    float col = 0.0;
    float test = (5.0 + 5.0*cos(0.5*time + atan(c.y,c.x))) * 10.0;
    
    if(len > test && len < (test + 10.0)){
        col = 1.0 - abs(len - test - 5.0) / 5.0;
    }
    
    glFragColor = vec4(0.5*col,col,0.0,1.0);
}

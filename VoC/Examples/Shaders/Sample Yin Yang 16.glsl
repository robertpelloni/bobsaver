#version 420

// original https://www.shadertoy.com/view/tdG3Dd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

mat2x2 rotate(float angle) {
    float s = sin(angle);
    float c = cos(angle);
    return mat2x2(c, -s, s, c);
}
vec3 yy(vec2 uv) {
    float angle = time*.5;
    vec3 color = vec3(.2,0,0);
    
    for(int i = 0 ; i < 10 ; i ++) {
        if( length(uv) > 1.) {
            break;
        }
        
        uv *= rotate(angle+float(i)*.5);
        uv*=2.;
        uv.x -=sign(uv.x); 
        
        color = vec3(sign(uv.y));
    }
    
    return color;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy*2.-resolution.xy)/resolution.y;
    glFragColor = vec4(yy(uv),1);
}

#version 420

// original https://www.shadertoy.com/view/NlB3zw

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 spin(vec2 uv,float t){
    return vec2(uv.x*cos(t)-uv.y*sin(t),uv.y*cos(t)+uv.x*sin(t));
}

void main(void)
{
    vec2 uv = (2.*gl_FragCoord.xy-resolution.xy)/resolution.y; //-1 <> 1

    uv=spin(uv,time);
    
    vec3 color = 0.5 + 0.5*cos(time+uv.xyx+vec3(0,2,4));
    
    float s=0.1;
    for(int i=0;i<20;i++){
        uv=abs(uv)-s;
        uv=spin(uv,cos(time));
    }

    vec3 col = vec3(0.);

    col += vec3(0.03/length(uv));
    col *= color;
    
    glFragColor = vec4(col,1.0);
}

#version 420

// original https://www.shadertoy.com/view/4tfXW8

uniform float time;

out vec4 glFragColor;

void main(void) {
    vec2 pos=gl_FragCoord.xy;
    float col=sin( dot(pos+=pos,pos) - max(pos.x,pos.y) - 4.*time);    
    glFragColor=vec4(col,col,col,1.0);
}


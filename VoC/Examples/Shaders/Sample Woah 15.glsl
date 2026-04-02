#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main( void ) {
    vec2 uv = ( gl_FragCoord.xy / resolution.xy ) * 2.0 - 1.0;
    uv.x *= resolution.x / resolution.y;    
    uv/=pow(length(uv),sin(time*1.)*2.+2.)*.1;
    uv*=mat2(cos(time*3.),-sin(time*3.),sin(time*3.),cos(time*3.));
    uv+=time*42.;
    glFragColor = vec4(sin(uv),sin(time*1337.),1);
}//trp

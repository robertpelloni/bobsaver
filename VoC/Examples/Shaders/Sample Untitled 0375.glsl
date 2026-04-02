#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main( void ) {
    vec2 pos=(gl_FragCoord.xy/resolution.xy)*2.0-1.0;
    pos.x*=resolution.x/resolution.y;
    float col=1.75;
    col=mod(pos.x,0.2)+mod(pos.y,0.2);
    float len=length(pos);
    vec2 uv=vec2(col)+(pos/len)*cos(len*2.0-time*4.0)*0.8;
    vec3 color=vec3(col*abs(sin(time))/8.0,uv);
    glFragColor=vec4(color,1.0);
}

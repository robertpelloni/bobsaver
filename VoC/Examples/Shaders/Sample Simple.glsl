#version 420

uniform float time;
uniform vec2 resolution;

out vec4 glFragColor;

void main( void ) {
    vec2 p = ( gl_FragCoord.xy / resolution.xy );
    float col = sin(p.x*100.+time*2.+sin(sin(p.x*100.0)*2.0+p.y*90.0+time*4.)*2.0);
    glFragColor = vec4( col );
}

#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main( void ) {

    vec2 pos = -1.0+2.0*( gl_FragCoord.xy / resolution.xy );
    pos.x *= resolution.x/resolution.y;
    vec2 p = pos;
    float color = 0.0;
    for (int i = 0; i < 10; i++) {
        p = vec2(sin(time)*p.x - cos(time)*p.y, sin(time)*p.y + cos(time)*p.x);
        p = abs(p);
        p -= color;
        color += sin(float(i)+length(pos))*length(p);
    }

    glFragColor = vec4( sin(color*8.0)*0.5+0.5 );

}

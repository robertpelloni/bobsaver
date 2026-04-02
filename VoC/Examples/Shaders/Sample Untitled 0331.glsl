#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main( void ) {

    vec2 p = ( gl_FragCoord.xy / resolution.xy );
    p = 2.0 * p - 1.0;
    p.x *= resolution.x / resolution.y;
    p*=0.1;
    float color = 0.0;
    float d0 = (length(p));
    vec2 q = mod(sin(p * 3.141592 * 2.0) - 0.5, 1.0) - 0.5;
    vec2 r = mod(cos(q * 3.141592 * 3.0) - 0.5, 1.0) - 0.5;
    float d = length(d0);
    float dr = length(r);
    float w1 = cos(time - 5.0 * d * 3.141592) * 2. ;
    float w2 = cos(-8.2 * dr * 3.141592*sin(d*9. - dr*w1*3.3 + w1*d0 + time*0.3)) * 1. ;
    
    color = w1-w2 -d*d0;

    glFragColor = vec4( vec3( -color, abs(color) * 0.5, cos( color + time * 2.0 ) * 0.75 ), 1.0 );

}

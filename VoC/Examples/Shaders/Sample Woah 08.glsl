#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main( void ) {

    vec2 surfacepos=gl_FragCoord.xy/resolution.y*2.-1.;
    vec2 position = surfacepos * 64.0;
    vec2 m=mouse-0.5;
    m.x*=2.;
    position = floor(position/(4.*distance(surfacepos,m) ));
    
    float color = mod(position.x + position.y, 2.0);
    
    glFragColor = vec4( vec3(color), 1.0 );

}

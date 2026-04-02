#version 420

uniform float time;
uniform vec2 resolution;

out vec4 glFragColor;

float rand(in vec2 p)
{
    return abs( fract( sin(p.x * 95325.328 + p.y * -48674.077) + cos(p.x * -46738.322 + p.y * 76485.077) + time/3. ) -.5)+.5;
}
    
void main( void ) {
    
    vec2 position = ( gl_FragCoord.xy ) *.08;

    vec3 color = vec3(rand( vec2(floor(position.x) , floor(position.y) ) ), rand( vec2(floor(position.y) , floor(position.x) ) ) , rand( vec2(floor(position.x*.5) , floor(position.y*.5) ) ));
    float scale = 1.-pow( pow( (mod( position.x, 1.)-.5) , 2.) + pow( (mod( position.y, 1.)-.5), 2.), .7 );
    
    glFragColor = vec4( color*scale, 1.);
}

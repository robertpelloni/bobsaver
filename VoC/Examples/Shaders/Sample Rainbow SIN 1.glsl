#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main( void ) {

    vec2 position = ( gl_FragCoord.xy / resolution.xy );
    position.y *= 4.0+sin(time);
    position.y -= 2.0;
    
    float color = 0.0;

    color = 1.0-abs(sin(time*1.0-position.x*3.142*1.0)-position.y)*0.5;
    float color2 = 1.0-abs(sin(time*1.3-position.x*3.142*1.0)-position.y-1.0)*0.5;
    float color3 = 1.0-abs(sin(time*1.6-position.x*3.142*1.0)-position.y+1.0)*0.5;
    
    glFragColor = vec4( vec3( color2, color , color3 ), 1.0 );

}

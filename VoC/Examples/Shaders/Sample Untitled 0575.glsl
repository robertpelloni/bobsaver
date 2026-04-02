#version 420

/*
Made by Trixelized
bit.ly/trixlink
*/

uniform float time;
uniform vec2 resolution;

out vec4 glFragColor;

void main( void ) {

    vec2 p = 1.*( gl_FragCoord.xy / resolution.xy );

    float col = .5;
    for (float i=0.; i<1.; i+=0.5) {
        col *= sin(time * 3. + p.y * (16. + i * 100.)) + cos(time/3. + i*time*3. + p.x * (16. + i * 500.))/1.3;
    }
    
    col = col+cos(time+p.x)*0.4;
    
    glFragColor = vec4( vec3( col*col*0.75, col*col*0.25, col*0.5 ), 1.0 );

}

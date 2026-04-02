#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main( void ) {

    vec2 position = ( gl_FragCoord.xy / resolution.xy );// + mouse / 4.0;
    vec2 offpos = position + vec2(0.5);

    float color = 0.0;
//    color += sin( position.x * 20.0 - time) * 0.5;
//    color += sin( position.y * 20.0 + time+ 3.14) * 0.5;
    color += sin( offpos.x * offpos.y * (20.0) + time * 10.0) * 1.0;
    color += sin( (1.0 - offpos.x) * offpos.y * 50.0 + time * 5.0) * 1.0;
//    color += cos( position.y * 40.0 * sin(time)) * cos(time * 8.0);
    
    float gcol = 0.0;
    gcol += cos( position.x * 40.0 * cos(time + 3.14/2.0)) * 0.5;
    gcol += cos( position.y * 40.0 * sin(time + 3.14/2.0)) * 0.5;
    
    float bcol = 0.0;
    bcol += sin( position.x * 80.0 * cos(time + 3.14/4.0)) * 0.5;
//    bcol += tan( position.y * 80.0 * sin(time + 3.14/4.0)) * 0.5;
//    color += sin( position.x * cos( time / 15.0 ) * 80.0 ) + cos( position.y * cos( time / 15.0 ) * 10.0 );
//    color += sin( position.y * sin( time / 10.0 ) * 40.0 ) + cos( position.x * sin( time / 25.0 ) * 40.0 );
//    color += sin( position.x * sin( time / 5.0 ) * 10.0 ) + sin( position.y * sin( time / 35.0 ) * 80.0 );
//    color *= sin( time / 10.0 ) * 0.5;

    glFragColor = vec4( vec3( color, color * 0.5, sin( color + time / 3.0 ) * 0.75 ), 1.0 );
//    glFragColor = vec4(color, gcol, bcol, 1.0);
//    glFragColor = vec4(color, color, color, 1.0);
}

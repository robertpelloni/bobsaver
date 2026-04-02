#version 420

// original https://www.shadertoy.com/view/XtXGDN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float s( float b ){
    return abs( b / 2. - mod( time * 9., b ) );
}
mat3 m = mat3( s(2.), s(17.), s(23.), 
               s(11.), s(13.), s(7.),
               s(19.), s(3.), s(5.) );
void main() {
    glFragColor = vec4( normalize( m * ( gl_FragCoord.xyy - 1e2 ) ), 1. );
}

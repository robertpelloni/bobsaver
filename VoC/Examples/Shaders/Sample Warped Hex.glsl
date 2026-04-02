#version 420

// Warped Hex
// By: Brandon Fogerty
// xdpixel.com

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float hex( vec2 p )
{        
    p.y += mod( floor(p.x), 4.0) * 0.5;
    p = abs( fract(p)- 0.5 );
    return 1.-abs( max(p.x*1.5 + p.y, p.y * 2.0) - 1.0 )*10. ;
}

void main( void ) {

    vec2 uv = ( gl_FragCoord.xy / resolution.xy ) * 2.0 - 1.0;
    uv.x *= resolution.x / resolution.y;    
    uv/=dot(uv,uv)*.5;
    uv.x+=time;
    glFragColor = vec4( vec3(hex(uv)), 1.0 );

}

#version 420

// Flower Matrix
// By: Brandon Fogerty
// xdpixel.com

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main( void ) 
{

    vec2 uv = ( gl_FragCoord.xy / resolution.xy ) * 2.0 - 1.0;
    uv.x *= resolution.x/resolution.y;
    
    
    vec3 finalColor = vec3( 0.0, 0.0, 0.0 );

    float a = atan( uv.y / uv.x );
    float r = length( uv );
    

    float timeT = sin(time) * 0.5 + 0.5;
    float move = mix( -0.8, 0.8, timeT );
    
         float t = abs( sin(((a + r*move)* 3.0)) * 1.0 );
    
         finalColor += vec3( 8.0 * t, 4.0 * t, 2.0 * t );
    
         finalColor *= 1.0-r;
    
    float g = -mod( gl_FragCoord.y + time, cos( gl_FragCoord.x ) + 0.004 ) * 0.5;
    finalColor *= vec3( 0.0, g, 0.0 );
    
    glFragColor = vec4( finalColor, 1.0 );

}

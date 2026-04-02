#version 420

// original https://www.shadertoy.com/view/WlSGDh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec2 center = vec2(sin( time*0.923 )*0.17,sin( time*0.7125)*0.22) + vec2( 0.51, 0.49 );
    vec2 center2 = vec2(sin( time*0.9923 )*0.14,sin( time*0.87125)*0.21) + vec2( 0.55, 0.51 );;
    vec2 center3 = vec2(sin( time*0.77 )*0.18,sin( time*0.837125)*0.192) + vec2( 0.53, 0.45 );;
    vec2 center4 = vec2(sin( time*0.577 )*0.177,sin( time*0.637125)*0.1792) + vec2( 0.5, 0.5 );;
    float radius = 1.2;
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;

    // Time varying pixel color
//    vec3 col = 0.5 + 0.5*cos(time+uv.xyx+vec3(0,2,4));
    float dist = distance( center, uv );
    vec3 col = vec3( sin( 100.0*dist ), sin( 110.0*dist ), sin( 120.0*dist ) );
    col *= max( 0.0, (1.0-dist*3.0) );
    
    dist = distance( center2, uv );
    vec3 col2 = vec3( sin( 100.0*dist ), sin( 110.0*dist ), sin( 120.0*dist ) );
    col2 *= max( 0.0, (1.0-dist*3.0) );

    dist = distance( center3, uv );
    vec3 col3 = vec3( sin( 100.0*dist ), sin( 110.0*dist ), sin( 120.0*dist ) );
    col3 *= max( 0.0, (1.0-dist*3.0) );

    dist = distance( center4, uv );
    vec3 col4 = vec3( sin( 100.0*dist ), sin( 110.0*dist ), sin( 120.0*dist ) );
    col4 *= max( 0.0, (1.0-dist*3.0) );
    
    col += col2;
    col += col3;
    col += col4;
    
    // Output to screen
    glFragColor = vec4(col,1.0);
}

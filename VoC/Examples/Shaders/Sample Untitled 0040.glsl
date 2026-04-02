#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;
const float PI = 3.141592;
void main( void ) {
    float size = 30.0;
    float color = 0.0;

    //    color
    //    vec3 mColor = vec3( 1.0, ( gl_FragCoord.xy / resolution.xy ) );
    vec3 mColor = vec3( (sin(time * 0.1)+1.0)*0.5, ( gl_FragCoord.xy / resolution.xy ) );

    float r = 100.0;
    float speed = 5.0;

    color += size / distance( gl_FragCoord.xy, mouse.xy*resolution.xy + vec2( cos((0.0*120.0)/180.0*PI-time*speed) * r, sin((0.0*120.0)/180.0*PI-time*speed) * r ) );
    color += size / distance( gl_FragCoord.xy, mouse.xy*resolution.xy + vec2( cos((1.0*120.0)/180.0*PI-time*speed) * r, sin((1.0*120.0)/180.0*PI-time*speed) * r ) );
    color += size / distance( gl_FragCoord.xy, mouse.xy*resolution.xy + vec2( cos((2.0*120.0)/180.0*PI-time*speed) * r, sin((2.0*120.0)/180.0*PI-time*speed) * r ) );
    color += size * 0.2 / distance( gl_FragCoord.xy, mouse.xy*resolution.xy + vec2( cos((0.5*120.0)/180.0*PI+time*speed) * r * 0.5, sin((0.5*120.0)/180.0*PI+time*speed) * r * 0.5 ) );
    color += size * 0.2 / distance( gl_FragCoord.xy, mouse.xy*resolution.xy + vec2( cos((1.5*120.0)/180.0*PI+time*speed) * r * 0.5, sin((1.5*120.0)/180.0*PI+time*speed) * r * 0.5 ) );
    color += size * 0.2 / distance( gl_FragCoord.xy, mouse.xy*resolution.xy + vec2( cos((2.5*120.0)/180.0*PI+time*speed) * r * 0.5, sin((2.5*120.0)/180.0*PI+time*speed) * r * 0.5 ) );
    color += size * 0.05 / distance( gl_FragCoord.xy, mouse.xy*resolution.xy + vec2( cos((0.0*120.0)/180.0*PI-time*speed) * r * 0.2, sin((0.0*120.0)/180.0*PI-time*speed) * r * 0.2 ) );
    color += size * 0.05 / distance( gl_FragCoord.xy, mouse.xy*resolution.xy + vec2( cos((1.0*120.0)/180.0*PI-time*speed) * r * 0.2, sin((1.0*120.0)/180.0*PI-time*speed) * r * 0.2 ) );
    color += size * 0.05 / distance( gl_FragCoord.xy, mouse.xy*resolution.xy + vec2( cos((2.0*120.0)/180.0*PI-time*speed) * r * 0.2, sin((2.0*120.0)/180.0*PI-time*speed) * r * 0.2 ) );
    glFragColor = vec4( vec3( color ) * mColor, 1.0 );
}

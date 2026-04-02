#version 420

uniform float time;
uniform vec2 resolution;

out vec4 glFragColor;

void main( void ) 
{
vec2 uv = ( gl_FragCoord.xy / resolution.y );
vec3 color = vec3(fract(sin(dot(floor(floor(uv.xy*floor(fract(time*0.1)*12.0))+time*3.0),vec2(5.364,6.357)))*357.536));
glFragColor = vec4(color,1.0);
}

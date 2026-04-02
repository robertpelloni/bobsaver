#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float rand(vec2 n) {  return fract(sin(dot(n, vec2(12.9898, 4.1414))) * 43758.5453); }
float noise(vec2 p){
    vec2 ip = floor(p);
    vec2 u = fract(p);
    u = u*u*(3.0-2.0*u);
    
    float res = mix(
        mix(rand(ip),rand(ip+vec2(1.0,0.0)),u.x),
        mix(rand(ip+vec2(0.0,1.0)),rand(ip+vec2(1.0,1.0)),u.x),u.y);
    return res*res;
}

vec2 p, m;
vec3 color;
void main( void ) {
    p = (gl_FragCoord.xy / resolution.xy);
    m = vec2(time * 10., 0) ;

    glFragColor = vec4(vec3(noise(p * 2.5 + m), noise(p * 1.25 + m) , noise(p * 5.0 + m)), 1.0 );

}

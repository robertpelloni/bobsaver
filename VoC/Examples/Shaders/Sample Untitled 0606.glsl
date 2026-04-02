#version 420

uniform float time;
uniform vec2 resolution;

out vec4 glFragColor;

float rand(vec2 n) { 
    return fract(sin(dot(n, vec2(12.9898, 4.1414))) * 43758.5453);
}

float noise(vec2 p){
    vec2 ip = floor(p);
    vec2 u = fract(p);
    u = u*u*(3.0-2.0*u);
    
    float res = mix(
        mix(rand(ip),rand(ip+vec2(1.0,0.0)),u.x),
        mix(rand(ip+vec2(0.0,1.0)),rand(ip+vec2(1.0,1.0)),u.x),u.y);
    return res*res;
}

void main( void ) {
    vec2 a = resolution.xy / min(resolution.x, resolution.y);
    vec2 p = ( gl_FragCoord.xy / resolution.xy ) * a;

    float v = 0.0;
    
    for(float i = 20.0; i>0.0;i-= 1.0) {
        v = noise(p * 10.0 + v * i+ vec2(0.0, time * i));
    }
    
    glFragColor = vec4( vec3(v), 1.0 );

}

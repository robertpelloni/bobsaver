#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main( void ) {
    
    vec2 pos = ( gl_FragCoord.xy / resolution.xy ) - vec2(0.5,0.5);    
        float horizon = -0.0; 
        float fov = 0.5; 
    float scaling = pow(2., -2.5 + 2.5 * sin(sin(time)));
    
    vec3 p = vec3(pos.x, fov, pos.y - horizon);      
    vec2 s = vec2(p.x/p.z, p.y/p.z) * scaling;
    
    //checkboard texture
    float color = sign((mod(s.x, 0.1) - 0.05) * (mod(s.y + 0.5 * sign(pos.y) * time, 0.1) - 0.05));    
    //fading
    color *= p.z*p.z*10.0/scaling;
    
    glFragColor = vec4( vec3(color), 1.0 );

}

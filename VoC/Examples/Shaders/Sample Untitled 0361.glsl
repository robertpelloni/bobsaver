#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main( void ) {
    
    vec2 pos = ( gl_FragCoord.xy / resolution.xy ) - vec2(0.5);    
    
    float horizon = sin(time*0.5) * 0.75; 
    float fov = 0.5; 
    float scaling = 2.;
    
    vec3 p = vec3(pos.x - (mouse.x - 0.5), fov, pos.y - horizon);
    vec2 s = vec2(p.x / p.z, p.y / p.z) * scaling;
    
    //checkboard texture
    float color = sign((mod(s.x, 1.) - 0.5) * (mod(abs(0.5-s.y)+time*8., 1.) - 0.5));    
    //fading
    color = max(0.0, color * pow(p.z, 3.) * 10.0);
    
    glFragColor = vec4(mix(vec3(1.,0.2,0.), vec3(0.,0.9,1.0), step(horizon,pos.y)) * vec3(color / (color + 1.0)), 1.0 );

}

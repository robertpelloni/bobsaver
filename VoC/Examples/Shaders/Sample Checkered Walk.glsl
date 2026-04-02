#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;
uniform sampler2D texture;

out vec4 glFragColor;

void main( void ) {    
    vec2 pos = ( gl_FragCoord.xy / resolution.xy ) - vec2(0.5,0.5);    
    
    vec3 storedCamPos = texture2D(texture, vec2(0.0, 0.0)).xyz;
    vec3 camPos = storedCamPos;
    
    float t = (-0.5+mouse.x) * 10.0;
    
    if(floor(gl_FragCoord.x) + floor(gl_FragCoord.y) == 0.0) {
        camPos.x += sin(t) * 0.01;
        camPos.y += cos(t) * 0.01;
        
        glFragColor = vec4(mod(camPos, 1.0), 1.0);    
        
        return;
    }
    
        float horizon = -0.0; 
        float fov = 0.3; 
    float scaling = 0.1;
    
    mat2 rot = mat2(cos(t),sin(t),-sin(t),cos(t)); // rot 2d pos ;
    
    vec3 p = vec3(pos.x, fov, pos.y - horizon + cos(time * 10.0) * 0.04);    
    
    p.xy *= rot;
    
    vec2 s = vec2(p.x/p.z, p.y/p.z) * scaling;
    
    
    //checkboard texture
    
    float dupa = 1.0;
    float color =1.0;
    if(pos.y < 0.0)
         dupa *= -1.0;
    
    color = sign((mod(s.x + dupa * mod(camPos.x * 2.0 * 0.05, 1.0), 0.1) - 0.05) * (mod(s.y + dupa * mod(camPos.y * 2.0 * 0.05, 1.0), 0.1) - 0.05));
    color *= p.z*p.z*4.0;
    
          glFragColor = vec4( 0.5-p.y,0.2,0.6, 1.0 );
    
    //fading
    
    
    glFragColor += vec4( vec3(color), 1.0 );

}

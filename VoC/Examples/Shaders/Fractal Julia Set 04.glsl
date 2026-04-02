#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main( void ) {

    vec2 z = 1.15*(-resolution.xy+2.0*gl_FragCoord.xy)/resolution.y; //pixel coordinates
    
    vec2 c = 0.51*cos( vec2(0.130,1.35708) + 0.1*time) - 0.25*cos(vec2(0.120,1.25708) + 0.2*time);
    
    float intensity = 1e20;
    for (int i=0; i<128; i++)
    {
        z = vec2 (z.x*z.x - z.y*z.y, 2.0*z.x*z.y) + c;
        intensity = min(intensity, dot(z,z) ); 
    }
    
    intensity = 0.30 - log(intensity)/12.0;
    
    glFragColor = vec4(intensity, intensity*intensity, intensity*intensity, 1.0);
}

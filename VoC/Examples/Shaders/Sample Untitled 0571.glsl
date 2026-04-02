#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main( void ) {

    vec2 position = ( gl_FragCoord.xy / resolution.xy );

    float px = position.x * resolution.x;
    float py = position.y * resolution.y;
    
    px /= 32.;
    py /= 32.;
    
    float mul = floor(mod(px, 2.0)) * floor(mod(py, 2.0));
    
    mul *= sin(time/2.0 + floor(px));
    mul *= cos(time/2.0 + floor(py));

    glFragColor = vec4(1.0, 1.0, 1.0, 1.0) * mul;

}

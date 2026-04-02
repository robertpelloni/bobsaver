#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main( void ) {
    
    vec2 point1 = vec2(0.2, (sin(time) / 2.0) + 0.5);
    vec2 point2 = vec2(0.2, ((-sin(time)) / 2.0) + 0.5);
    
    vec2 position = gl_FragCoord.xy / resolution.xy;
    position.x *= resolution.x / resolution.y;
    
    float deepness = sin((distance(position, point1) * 40.0) - (time * 10.0)) + sin((distance(position, point2) * 40.0) - (time * 10.0));
    
    float pixelIntensity = (deepness / 2.0) + 0.5;
    
    glFragColor = vec4(vec3(pixelIntensity), 1.0);

}

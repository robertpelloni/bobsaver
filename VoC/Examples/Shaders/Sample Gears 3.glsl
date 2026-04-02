#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float drawCog(vec2 position, vec2 center, float radius, float rotation, float n) {
    float value = 0.0;
    
    vec2 offset = center - position;
    float toAdd = abs(floor(sin(atan(offset.y, offset.x) * n + rotation * 10.0 / n))) * 0.02;
    
    float offsetLen = length(offset);
    
    if(offsetLen < radius * 0.7 && offsetLen > radius * 0.2 && sin(atan(offset.y, offset.x) * floor(n / 2.0) + rotation * (10.0 / n / 2.0)) < 0.0)
        offsetLen = 1.0;
    
    value = smoothstep(radius - 0.001 + toAdd, radius + toAdd, offsetLen);
    
    return value;
}

void main( void ) {

    vec2 position = ( gl_FragCoord.xy / resolution.yy );
    position += vec2(0.75,0.5); 
    position *= 0.5; 
    float totval = 0.0; 
    for (int i = 0; i < 10; i++) {
        float tt = time*5.0; 
        float value = 1.0; 
        value = min(value, drawCog(position, vec2(0.5, 0.5), 0.1, tt * 10.0+float(i)*0.04*5.0, 15.0)); 
        value = min(value, drawCog(position, vec2(0.73, 0.5), 0.1, -tt * 10.0+float(i)*0.04*5.0 + 4.6, 15.0)); 
        value = min(value, drawCog(position, vec2(1.055, 0.5), 0.2, tt * 19.0+float(i)*0.02*5.0 - 10.0, 30.0)); 
        totval += value/10.0;
        
    }
    
    vec3 color = vec3(totval);
    
    glFragColor = vec4(color, 1.0 );

}

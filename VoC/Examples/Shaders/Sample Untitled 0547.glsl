#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    
    vec2 p = (gl_FragCoord.xy * 2.0 - resolution) / min(resolution.x, resolution.y);
    vec3 color = vec3(0.2, 0.1, 0.8);
    
    float f = 0.9;
    float PI = 3.141585;
    for(float i = 0.0; i < 65.0; i++){
        
        float s = tan(time + i * 2. * PI / 10.0) * 0.3*sin(time);
        float c = tan(time + i * 3. * PI / 10.0) * 0.40;
 
        f += 0.00023 / (abs(p.x + c) * abs(p.y + s));
    }
    
    
    glFragColor = vec4(
        f * color.x + p.x, 
        f * color.y - p.y,
        f * color.z * (p.x + p.y), 1.0);
}

#version 420

// Posted by Trisomie21

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define LAYERS 5.0

float rand(vec2 co){ return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453); }

void main( void ) {
    
    vec2 pos = gl_FragCoord.xy - resolution.xy*.5;
    float dist = length(pos) / resolution.y;
    vec2 coord = vec2(dist, atan(pos.x, pos.y) / (3.1415926*2.0));
    
    vec3 color = vec3(0.0);
    for (float i = 0.0; i < LAYERS; ++i)
    {
        float t = i*100.0+time*(i*i);
        
        vec2 uv = coord;
        
        uv.y += (i*.1)*(i*.02);
        uv.y = fract(uv.y);
        
        float r = pow(uv.x, .1) - (t*.001);
        
        vec2 p = vec2(r, uv.y*.5);
        
        // UV coord in cell
        uv.x = mod(r, 0.01)/.01;
        uv.y = mod(uv.y, 0.02)/.02;
    
        // Shape
        float a = 1.0-length(uv*2.0-1.0);
    
        // Color
        vec3 m = fract(r*100.0 * vec3(0.25, 1.0, -0.5))*.8+i*.2;
        
        // Mask cell
        p = floor(p*100.0);
        float d = (rand(p)-0.6)*10.0;
        d = clamp(d*dist, 0.0, 1.0);
    
        color = max(color, a*m*d);
    }

    glFragColor =  vec4(color, 1.0 );
}

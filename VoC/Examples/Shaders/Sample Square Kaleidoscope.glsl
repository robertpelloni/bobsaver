#version 420

// original https://www.shadertoy.com/view/3t2XRG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float in_square(vec2 uv, float square_size)
{
    // Changing this value causes some funky %&*$
    float a = time + length(uv) * 3.141592653589 * sin(time * 0.12316);
    float s = sin(a);
    float c = cos(a);
    
    uv *= mat2(c, -s, s, c);
    
    return float(uv.x > -square_size && uv.x < square_size && uv.y > -square_size && uv.y < square_size);
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy/resolution.xy);
    vec3 color = vec3(0.0,0.0,1);
    
    uv = uv * 2.0 - 1.0;
    uv.x *= resolution.x / resolution.y;
    
    
    float ratio = resolution.x / resolution.y;
    
    uv *= 6.0;
    
    float a = time * 0.4 + length(uv) * 0.005 * sin(time * 0.25);
    float s = sin(a);
    float c = cos(a);
    
    uv *= mat2(c, -s, s, c);
    
    vec2 guv = fract(uv) - 0.5;
    vec2 id = floor(uv);
    
    float square_size = 1.00 + (sin(time * 0.623) + 1.0) * 0.5 * length(uv) * 0.125;    
    
    
    
    float square = 0.0;
    for(float col = -1.0; col < 2.0; col += 1.0)
    {
        for(float row = -1.0; row < 2.0; row += 1.0)
        {            
            square += in_square(vec2(guv.x + col, guv.y + row), square_size);
        }
        
    }    
    vec3 col = 0.5 + sin(time + vec3(square * 0.25, square * 2.354126, square * 13.42)) * 0.5;
    
  
   
    glFragColor = vec4(col, 1.0);
}

#version 420

// original https://www.shadertoy.com/view/tdtyRX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.1415926538
#define SIN60 0.86602540378

vec2 rotate2D(vec2 coordinates, float angle){
    float sinA = sin(angle);
    float cosA = cos(angle);
    coordinates =  mat2(cosA,-sinA,
      sinA,cosA) * coordinates;
    return coordinates;
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy;    
    
    uv *= 2.0;
    uv -= 1.0;
    uv.x /= resolution.y / resolution.x;
    uv = rotate2D(uv, time * 0.45);
    
    float finalRed = 0.0;
    
    float finalWhite = 0.0;
    for(float x = -1.; x <= 1.; x++)
        for(float y = -1.; y <= 1.; y++)
        {
            vec2 coordinates = uv + vec2(x, y) * 0.002;    

            float sideA = dot(coordinates, vec2(SIN60, 0.5));
            float sideB = dot(coordinates, vec2(-SIN60, 0.5));
            float bottom = -coordinates.y;

            float triangle = max(sideA, max(sideB, bottom));

            float sinIncrement = (sin(time * 4.0) + 1.0 + cos(time * 2.0)) * 0.8;
            float fractalTriangle = fract(1.0 / triangle + time * 3.0 + sinIncrement);
            float white = fract(1.0 / triangle + time * 3.0 + sinIncrement);
            white = step(white, 0.1);
            finalRed += step(triangle, 0.0995);
            
            float angle = atan(coordinates.x, coordinates.y) / PI;
                        
            for(float n = 1.0; n >= -1.0; n -= 0.2/3.0)
                white += step(angle, n + 0.005) * (1.0 - step(angle, n - 0.005)) * 0.75;                
                                    
            white = clamp(white, 0., 1.);
            float innerTriangleRed = step(triangle, 0.09);
            float innerTriangleWhite = step(triangle, 0.098);
            white -= innerTriangleWhite;
            finalRed -= innerTriangleRed;
            
            white = clamp(white, 0.0, 1.0);
            finalWhite += white;
            
        }
   
    finalRed /= 9.0;
    finalWhite /= 9.0;
    glFragColor = vec4(vec3(finalWhite) + vec3(finalRed, 0.0, 0.0),1.0);
}

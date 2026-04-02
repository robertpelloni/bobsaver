#version 420

// original https://www.shadertoy.com/view/MlBGW3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float k;
float centerBlack;
float depth;
float rotation;

vec2 p;
vec2 uv;
vec3 textColor;

const float pi = 3.1416;
const float pi2 = 3.1416 * 2.0;

void main(void) {
       
    k = time / 1.8;
    uv = gl_FragCoord.xy / resolution.xy;
    p = uv - .5;
    
    float dfc = distance(vec2(.5), uv);
    
    depth = 1.0 / dfc ;
    rotation = atan(p.y, p.x) / pi + sin(k / 4.0) + depth * cos(k * 0.3) * 0.2;
        
    centerBlack = (1.00 - cos(dfc * pi2)) * 0.1;
    
    vec2 pos = vec2(
            mod(depth + k * 8.0, pi2), 
            rotation 
    );
    
    float x = pos.x;
    float y = pos.y;
    
    float r = (25.0 + (sin(x - 0.5) + sin(y * pi) * 18.0) - sin(x * pi) * 19.0) * 0.3;
    float g = 1.0 + (sin(x + 0.6) * sin(y * pi ) );
    float b = 5.0 + (sin(x * 0.7) + sin(y * pi) * 5.0);
        
    textColor = vec3(r, b / 3.0, b) * vec3(b, r, g) / 5.0 ;
    
    glFragColor = vec4(textColor, 1.0) * centerBlack;
}

#version 420

// original https://www.shadertoy.com/view/llS3Dy

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define SQUARE_SIZE 64.0
void main(void)
{
    //vec2 uv = gl_FragCoord.xy / resolution.xy;
    vec2 myCoord;
    float angle = time;
    myCoord.x = gl_FragCoord.x * cos(angle) + gl_FragCoord.y * sin(angle);
    myCoord.y = gl_FragCoord.x * - sin(angle) + gl_FragCoord.y * cos(angle);
    
    float square_size = 5.0 + SQUARE_SIZE * (1.0 + sin(time) * 0.5 );
    float double_square_size = square_size * 2.0;
    float x = myCoord.x + sin(time * 2.0) * 32.0;
    float y = myCoord.y + cos(time * 4.0) * 32.0;
    vec3 f_color, b_color;
    if ( ((mod(x, double_square_size) < square_size) && (mod(y, double_square_size) < square_size) ) ||
        ((mod(x, double_square_size) >= square_size) && (mod(y, double_square_size) >= square_size) ) )
    {
        f_color = vec3(0.9,0.3,0.24);
        b_color = vec3(1.0,1.0,1.0);
    }else{
        f_color = vec3(0.18,0.37,0.87);
        b_color = vec3(0.0,0.0,0.0);
    }
    float weight = 0.5 + sin(time*2.4) * 0.4;
    vec3 color = mix(f_color, b_color, weight);
    glFragColor = vec4(color.x, color.y, color.z, 1.0);
    
}

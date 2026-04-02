#version 420

// original https://www.shadertoy.com/view/fls3WB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159265359
//RGB: 1/255
#define RGB 0.0039

float sharpRainbow(float y, vec2 st, float offset, float width) {
    float edge = y-(offset*width);
    return step(edge-width, st.y) - step(edge, st.y);
}
  
void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 st = gl_FragCoord.xy/resolution.xy;

    float width = (1.0/20.0);
    float y = 0.5 + (8.0*width/2.0) + sin(time+st.x*PI)*sin(time*1.5)*0.25;

    //original 1978 colors
    //TIL the original 1978 pride flag actually had 8 colors, until hot pink was dropped due to fabric shortage!
    //https://en.wikipedia.org/wiki/Rainbow_flag_(LGBT)
    vec3 pink   = vec3(255.0*RGB, 105.0*RGB, 180.0*RGB);
    vec3 red    = vec3(255.0*RGB, 000.0*RGB, 000.0*RGB);
    vec3 orange = vec3(255.0*RGB, 142.0*RGB, 000.0*RGB);
    vec3 yellow = vec3(255.0*RGB, 255.0*RGB, 000.0*RGB);
    vec3 green  = vec3(000.0*RGB, 142.0*RGB, 000.0*RGB);
    vec3 turq   = vec3(000.0*RGB, 192.0*RGB, 192.0*RGB);
    vec3 indigo = vec3(064.0*RGB, 000.0*RGB, 152.0*RGB);
    vec3 violet = vec3(142.0*RGB, 000.0*RGB, 142.0*RGB);

    vec3 color = mix(pink, indigo, (1.0 + sin(time))/2.0);
    color = mix(color, pink,    sharpRainbow(y, st, 0.0, width));
    color = mix(color, red,     sharpRainbow(y, st, 1.0, width));
    color = mix(color, orange,  sharpRainbow(y, st, 2.0, width));
    color = mix(color, yellow,  sharpRainbow(y, st, 3.0, width));
    color = mix(color, green,   sharpRainbow(y, st, 4.0, width));
    color = mix(color, turq,    sharpRainbow(y, st, 5.0, width));
    color = mix(color, indigo,  sharpRainbow(y, st, 6.0, width));
    color = mix(color, violet,  sharpRainbow(y, st, 7.0, width));

    // Output to screen
    glFragColor = vec4(color,1.0);
}

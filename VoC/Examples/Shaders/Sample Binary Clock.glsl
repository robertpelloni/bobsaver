#version 420

// original https://www.shadertoy.com/view/XtKXWd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;
uniform vec4 date;

out vec4 glFragColor;

#define CENTER (resolution.xy / 2.0)
#define THIRD (1.0 / 3.0)
#define SIXTH (1.0 / 6.0)
#define TWELFTH (1.0 / 12.0)
#define ON_COLOR vec4(1.0, 0.0, 0.0, 1.0)
#define OFF_COLOR vec4(0.3, 0.3, 0.3, 1.0)
#define BACKGROUND vec4(0.0, 0.0, 0.2, 1.0)
#define BLACK vec4(0.0)
#define RADIUS 0.06

vec4 display_digit(float decimal, vec2 uv, float x) {
    vec4 color = BLACK;
    
    for (float i = 0.0; i < 4.0; i++) {
        float bit_val = pow(2.0, i);
        float bit = floor(mod(decimal / bit_val, 2.0));
        vec2 center = vec2(x, i * 0.2 - 0.3);
        float dist = distance(uv, center);
        float circle = 1.0 - smoothstep(RADIUS - 0.005, RADIUS, dist);
        color += circle * mix(OFF_COLOR, ON_COLOR, bit);
    }
    
    return color;
}

//Display the hours component in two columns
vec4 display_hours(float hours, vec2 uv) {
    float tens = hours / 10.0;
    float ones = mod(hours, 10.0);
    return display_digit(tens, uv, -4.0 * SIXTH + TWELFTH) 
        + display_digit(ones, uv, -3.0 * SIXTH + TWELFTH);
}

//Display the minutes component in two columns
vec4 display_minutes(float minutes, vec2 uv) {
    float tens = minutes / 10.0;
    float ones = mod(minutes, 10.0);
    return display_digit(tens, uv, -TWELFTH)
        + display_digit(ones, uv, TWELFTH);
}

//Display the seconds component in two columns
vec4 display_seconds(float seconds, vec2 uv) {
    float tens = seconds / 10.0;
    float ones = mod(seconds, 10.0);
    return display_digit(tens, uv, 3.0 * SIXTH - TWELFTH)
        + display_digit(ones, uv, 4.0 * SIXTH - TWELFTH);
}

void main(void)
{
    //Get the UV Coordinates
    vec2 uv = (gl_FragCoord.xy - CENTER) / resolution.y;
    
    //Normalize the time components
    float hours = floor(date.w / 60.0 / 60.0);
    float minutes = floor(mod(date.w / 60.0, 60.0));
    float seconds = floor(mod(date.w, 60.0));
    
    glFragColor = BACKGROUND;
    
    //Display HH MM SS in binary
    if (uv.x < -THIRD) {
        glFragColor += display_hours(hours, uv);
    } else if (uv.x < THIRD) {
        glFragColor += display_minutes(minutes, uv);
    } else {
        glFragColor += display_seconds(seconds, uv);
    }
}

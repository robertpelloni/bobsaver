#version 420

// original https://www.shadertoy.com/view/WtlSD8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 CircleLightWithRGB(float circleLight, float r, float g, float b) {
    float red = circleLight * r;
    float green = circleLight * g;
    float blue = circleLight * b;
    return vec3(red, green, blue);
}

float CircleLight(vec2 uv, vec2 position, float outer_radius, float inner_radius) {
    // Distance from center to the pixel at (uv - position)
    float d = length(uv - position);
    
    // smoothstep(a, b, value) <=> easeInOut(a, b, value)
    // if d > outer_radius, return 0.
    // if d < inner_radius, return 1.
    // otherwise, map d smoothly between outer radius and inner radius.
    return smoothstep(outer_radius, inner_radius, d);
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    
    // Aspect ratio of the screen
    float aspect_ratio = resolution.x / resolution.y;
    
    // Center coordinates around (0, 0)
    vec2 offset = vec2(-0.5, -0.625);
    uv = uv + offset;
    
    // Equalize width and height
    uv.x = uv.x * aspect_ratio;
    
    // Outer radius of the desired circle
    float outer_radius = 0.4;
        
    // Inner radius of the desired circle
    float inner_radius = 0.125;
    
    // Determine the position of the circle.
    float x = 0.0;
    float y = 0.0;
    vec2 position = vec2(x, y);
    
    // Determine the brightness for each circle light.
    float light1 = CircleLight(uv, vec2(x,  - outer_radius / 1.5), outer_radius, inner_radius);
    float light2 = CircleLight(uv, vec2(x + outer_radius / 1.75, 0.0), outer_radius, inner_radius);
    float light3 = CircleLight(uv, vec2(x - outer_radius / 1.75, 0.0), outer_radius, inner_radius);
    
    // Calculate rgb color values for each circle light.
    float time = time / 0.7;
    float red = abs(sin(time));
    float green = abs(sin(time + 1.0));
    float blue = abs(sin(time + 2.0));
    vec3 color1 = CircleLightWithRGB(light1, red, green, blue);
    vec3 color2 = CircleLightWithRGB(light2, green, blue, red);
    vec3 color3 = CircleLightWithRGB(light3, blue, red, green);
    
    // Add up all of the colors.
    vec3 color_sum = color1 + color2 + color3;
     
    // Output to screen.
    glFragColor = vec4(color_sum, 0.5);
}

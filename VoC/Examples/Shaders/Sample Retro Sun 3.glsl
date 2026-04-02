#version 420

// original https://www.shadertoy.com/view/3d2cz3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float wave(vec2 uv, vec2 coords, float height, float frequency)
{
    float argument = coords.x + frequency * uv.x;
    float normalizedSine = height * sin(argument);
    
    float col = 1.0 - smoothstep(-2.,2., ((uv.y - coords.y) -normalizedSine)*resolution.y);
    col *= uv.y + 2.0;
    
    return col;
}

float sun(vec2 uv, vec2 center, float radius, float bloom)
{
    float dist = distance(uv, center);
    float circle = 1.0 - smoothstep(-3.,3., (dist-radius)*resolution.y);
    
    uv.y -= 0.;
    float visible = 1.0 - step(sin(uv.y * 40.0 + 5.0 * time) + 2.7 * uv.y - 0.3, 0.5);
    visible *= (uv.y + 0.5);
    return visible * circle + (1.0 - dist + bloom);
}

vec4 draw(vec4 inputImage, float mask, vec4 color)
{
    inputImage += mask * color;
    return inputImage;
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (2.0 * gl_FragCoord.xy - resolution.xy) / resolution.y;
    
    vec4 image = vec4(0.0, 0.0, 0.0, 0.0);
    
    float animatedValue = time + 0.3 * sin(time);
    float speed = 2.0;
    image = draw(image, wave(uv, vec2(animatedValue * speed ,-0.2), 0.04, 7.0), vec4(0.1, 0.2, 0.3, 0.0));
    image = draw(image, wave(uv, vec2(animatedValue * speed * 1.3 ,-0.4), 0.07, 6.0), vec4(0.1, 0.2, 0.3, 0.0));
    image = draw(image, wave(uv, vec2(animatedValue * speed * 1.5 ,-0.7), 0.1, 5.0), vec4(0.1, 0.2, 0.3, 0.0));
    image = draw(image, sun(uv, vec2(0.0, 0.4), 0.55, 0.3), vec4(1.0, 85.0/255.0, 0.0, 0.0));
    
    // Output to screen
    glFragColor = vec4(image);
}

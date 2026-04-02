#version 420

// original https://www.shadertoy.com/view/sddSR8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/**
 * create a rotation matrix for the given angle in radians
 */
mat2 getRotationMatrix(float angle) {
    float s = sin(angle);
    float c = cos(angle);

    return mat2(c, -s,
                s, c);
}

/**
 * draw the flower
 * position - gl_FragCoord.xy / uResolution.xy
 * 
 */
vec3 flower(
        vec2 position, 
        vec2 center, 
        float amplitude, 
        float size, 
        float frequency, 
        float blur, 
        float rotation, 
        vec2 skew,
        float index) {
    
    // by default, flower color will be black, and the background white
    vec3 color = vec3(1.0, 1.0, 1.0);
    vec2 figure = position - center;

    // draw the vertical line
    float lineSize = 0.005;

    // 0.1 * sin(5.0 * figure.y) makes the line be "wavy"
    // to flip horizontaly -> - 0.1 * sin(5.0 * figure.y)
    float verticalLine = smoothstep(lineSize, lineSize + lineSize / 2.0, abs(figure.x + 0.1 * sin(5.0 * figure.y)));

    // remove the 'top' part of the vertical line - strange way
    color *= 1.0 - (1.0 - verticalLine) * (1.0 - smoothstep(0.0, 0.1, figure.y));

    // animation
    mat2 mat = getRotationMatrix(time * index * 2.5);
    figure = mat * figure;

    // draw the flower
    figure += skew;
    float r = size + amplitude * cos(atan(figure.y, figure.x) * frequency + rotation);
    color *= smoothstep(r, r + blur, length(figure));

    // apply the colors
    return color;
}

/**
 * entry point
 */
void main(void)
{
    vec2 position = gl_FragCoord.xy / resolution.y - vec2(0.5, 0.0);
    position += 0.1 * sin(5.0 * position - time);
 
    vec3 color = mix(vec3(0.098, 0.7686, 0.5882), vec3(1.0, 1.0, 1.0), position.y); 

    vec3 fl1 = flower(position, vec2(0.5, 0.5),  0.1,  0.1, 10.0, 0.01, 0.0, vec2(0.0), -0.6);
    color = mix(vec3(1.0, 0.0, 0.0), color, fl1);

    vec3 fl2 = flower(position, vec2(0.3, 0.9),  0.1,  0.001, 4.0,  0.01, 0.0, vec2(0.0), 0.2);
    color = mix(vec3(0.902, 0.6471, 0.0), color, fl2);
    
    vec3 fl3 = flower(position, vec2(0.51, 0.83),  0.01, 0.09, 60.0, 0.01, 0.0, vec2(0.0), 0.3);
    color = mix(vec3(0.0, 0.2353, 1.0), color, fl3);
    
    vec3 fl4 = flower(position, vec2(0.1, 0.2),  0.2,  0.1, 7.0,  0.01, 0.0, vec2(0.0), -0.4);
    color = mix(vec3(0.0118, 0.549, 0.3412), color, fl4);

    vec3 fl5 = flower(position, vec2(0.55, 0.1), 0.05, 0.1, 3.0,  0.01, 0.0, vec2(0.0), 0.5);
    color = mix(vec3(0.5804, 0.2039, 0.5333), color, fl5);
    
    vec3 fl6 = flower(position, vec2(0.8, 0.3),  0.05, 0.1, 10.0, 0.01, 0.0, vec2(0.0), -0.6);
    color = mix(vec3(0.8431, 0.0353, 0.6157), color, fl6);

    vec3 fl7 = flower(position, vec2(0.15, 0.7), 0.01, 0.1, 10.0, 0.01, 0.0, vec2(0.0), 0.7);
    color = mix(vec3(0.0745, 0.6431, 0.5373), color, fl7);
    
    vec3 fl8 = flower(position, vec2(0.8, 0.8),  0.03, 0.1, 10.0, 0.01, 0.0, vec2(0.0), 0.8);
    color = mix(vec3(0.0745, 0.6431, 0.5373), color, fl8);

    glFragColor = vec4(color, 1.0);
}

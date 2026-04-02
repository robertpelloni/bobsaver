#version 420

// original https://www.shadertoy.com/view/3dGGzz

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy;
    vec2 center = resolution.xy * 0.5;
    float PI = radians(180.0);
    
    //constants
    float rad = 150.0;
    
    //main circle
    float dist = distance(gl_FragCoord.xy, center);
    float circle = dist - rad;
    float outline = clamp(abs(circle) - 1.0, 0.0, 1.0);
    float circleCol = mix(1.0, 0.0, outline);
    
    //center sine
    float sine = sin(((gl_FragCoord.y - (resolution.y * 0.5)) / (PI * 20.0)) + time);
    float sineDiv = gl_FragCoord.x - center.x + sine * 50.0;
    float sinClamp = clamp(sineDiv, 0.0, 1.0);
    float sineCropped = mix(0.0, 1.0, clamp(sinClamp - clamp(circle + 5.0, 0.0, 1.0), 0.0, 1.0));
    
    //Small circles
    vec2 mirrorUV = vec2(gl_FragCoord.x, abs(gl_FragCoord.y - center.y));
    float smallDist = distance(mirrorUV, vec2(center.x, center.y * 0.4));
    float smallCirc = smallDist - 25.0;
    float smallClamp = clamp(smallCirc, 0.0, 1.0);
    float smallCol = mix(1.0, 0.0, smallClamp);
    float inverted = smallCol - sineCropped * smallCol * 2.0;
    
    //combine
    float comp = sineCropped + circleCol + inverted;

    // Output to screen
    glFragColor = vec4(vec3(comp),1.0);
}

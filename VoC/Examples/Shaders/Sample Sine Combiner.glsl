#version 420

// original https://www.shadertoy.com/view/NtKSRm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float PI = 3.14159265;
const float ERR = 0.15;
const float ZOOM = 6.0;
const float SCROLL = 1.0;
const float AMP = 3.0;

void main(void)
{
    // scale pixel coordinates from -ZOOM PI to +ZOOM PI
    vec2 uv = (gl_FragCoord.xy/resolution.xy * ZOOM * PI) - ((ZOOM / 2.0) * PI);
    // scale x coordinates again to force square pixels
    // ((1, 1) is equally far in X and Y in real pixels from origin)
    float x = uv.x / (resolution.y / resolution.x);
    float y = uv.y;
    
    float scroll = time * SCROLL;
    
    //float x = (gl_FragCoord.xy.x / resolution.x * PI * 6.0) - (3.0 * PI);
    //float y = (gl_FragCoord.xy.y / resolution.y * 2.0f) - (1.0);

    // Time varying pixel color
    vec3 col = 0.5 + 0.5*cos(time+uv.xyx+vec3(0,2,4));
    
    float sinx;
    // create and add two scrolling sin waves
    //float f1 = sin(x + scroll);
    //float f2 = 2.85 * sin(0.2 * x + 0.1 + scroll * 3.0);
    float f1 = sin(x - scroll);
    float f2 = sin((x + scroll)* 6.0) / 5.0;
    float f3 = sin(0.33 * x * x + scroll);
    sinx = f1 + f2 + f3;
    
    // increase amplitude
    sinx = AMP * sinx;
    
    // stretch amplitude between 0 and 1 over time
    //sinx = sinx * cos(scroll);
    
    // draw axes
    if (
        abs(x - 0.0) < ERR / 2.0
        || abs(y - 0.0) < ERR / 2.0
    ) {
        col = vec3(0.6, 0.6, 0.7);
    }
    
    else {
        col = vec3(1.0);
    }
    
    // plot the final function
    if (abs(sinx - y) < ERR) {
        col = vec3(1.0, 0.0, 0.0);
    }
    
    // plot the final function
    if (abs(f1 - y) < ERR) {
        col = vec3(0.0, 0.0, 1.0);
    }
    
    // plot the final function
    if (abs(f2 - y) < ERR) {
        col = vec3(0.0, 1.0, 0.0);
    }
    
    // plot the final function
    if (abs(f3 - y) < ERR) {
        col = vec3(1.0, 1.0, 0.0);
    }
    
    // show straight line segment for scale
    if (
        abs(x - 1.0) < ERR && abs(y - 1.0) < ERR
        || abs(x - 2.0) < ERR && abs(y - 2.0) < ERR
        || abs(x - 3.0) < ERR && abs(y - 3.0) < ERR
        || abs(x - 4.0) < ERR && abs(y - 4.0) < ERR
        || abs(x - 5.0) < ERR && abs(y - 5.0) < ERR
        || abs(x - 6.0) < ERR && abs(y - 6.0) < ERR
    ) {
        col = vec3(1.0, 0.0, 0.9);
    }

    // Output to screen
    glFragColor = vec4(col,1.0);
}

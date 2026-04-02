#version 420

// original https://www.shadertoy.com/view/ldVfz3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// from https://gist.github.com/antoineMoPa/c457f391932f5d7f7bbb9a1eca01e3a8

float ratio = 1.8;

bool arr(float x, float y){
    float ay2 = abs(y - 0.5);
    return ay2 < x && ay2 > x - 0.5;
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    float x = uv.x * ratio;
    float y = uv.y;

    vec4 col = vec4(0.0);

    float y_num;

    y = y * 10.0;    
    y_num = y;
    y = mod(y, 1.0);

    if(mod(y_num, 2.0) < 1.0){
        x = -x * 10.0 + time;
    } else {
        x = x * 10.0 + time;
    }

    x = mod(x, 1.0);

    bool arrow = arr(x, y);

    if(y < 0.1){
        arrow = false;
    } else if(y > 0.9){
        arrow = false;
    }

    if(arrow){
        col = vec4(0.8, 0.8, 0.3, 1.0);
    } else {
        col = vec4(0.1);
    }

    col.a = 1.0;

    glFragColor = col;
}

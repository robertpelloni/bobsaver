#version 420

// original https://www.shadertoy.com/view/3tdyzn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float pi = 4.*atan(1.);

vec2 pForm(float t) {
    return vec2(t,sin(2.*pi*t+time));
}

bool checkerboard(vec2 v) {
    float sum = floor(v.x) + floor(v.y);
    return mod(sum,2.) < .5;
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv =  5.* ( 2.*gl_FragCoord.xy - resolution.xy ) / resolution.y;

    vec3 white = vec3(1.);
    vec3 black = vec3(0.);
    
    vec3 col;
    if(mod(uv.x,1.+(1.+cos(pi*time))/2.) < 1.) {
        if(mod(uv.y,1.+(1.+cos(pi*time))/2.) < 1.) {
            col = black;
        }
        else
            col = white;
    }
    else {
        if(mod(uv.y,1.+(1.+cos(pi*time))/2.) < 1.) {
            col = white;
        }
        else
            col = black;
    }

    //vec3 col = checkerboard(uv)?black:white;

    // Output to screen
    glFragColor = vec4(col,1.0);
}

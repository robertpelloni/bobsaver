#version 420

// original https://www.shadertoy.com/view/3ldyzn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float pi = 4.*atan(1.);

mat2 rotate(float a) {
    float c = cos(a);
    float s = sin(a);
    return mat2(c,s,-s,c);
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = 5.*(2.*gl_FragCoord.xy-resolution.xy)/resolution.y;

    // Time varying pixel color
    vec3 col = vec3(0.0);
    
    float sum = floor(uv.x) + floor(uv.y);
    if (mod(sum,2.) < .5) {
        float x = 2.*fract(uv.x)-1.;
        float y = 2.*fract(uv.y)-1.;
        x /= sqrt(2.);
        y /= sqrt(2.);
        vec2 diff = vec2(x,y)*rotate(pi/4.);
        float p = (101.+99.*cos(pi*time))/200.;
        float dp = pow(pow(abs(diff.x),p) + pow(abs(diff.y),p),1./p);
        if(dp > 1.) {
            col = vec3(0.);
        }
        else
            col = vec3(1.);
    }
    else {
        col = vec3(0.);
    }
    

    // Output to screen
    glFragColor = vec4(col,1.0);
}

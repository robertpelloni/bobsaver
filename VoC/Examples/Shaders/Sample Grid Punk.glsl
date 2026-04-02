#version 420

// original https://www.shadertoy.com/view/wtcyDs

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (gl_FragCoord.xy/resolution.xx -.5);
    //vec2 uv = (gl_FragCoord.xy / resolution.xx - 0.5)；
     float c = 0.02;
         uv.y+=.22;
    uv*= abs(cos(time) + 1.);

    uv*= mat2(sin(time),cos(time),-cos(time),sin(time));
    vec3 p = vec3(uv,1.0);
    c = .3/length(uv);
    vec3 mask = fract(p*10.);
    vec3 mask1 = fract(p*100.);
    // mask*= vec3(1.,0.,0.);
    if(mask.x > .05 && mask.y > .05) {
        mask = vec3(0.);
    } else {
        mask = vec3(1.)*c;
    }
    if(mask1.x > .05 && mask1.y > .05) {
        mask1 = vec3(0.);
    } else {
        mask1 = vec3(1.)*c;
    }
    mask += mask1;
    vec3 col = mask * abs(sin(time)) * vec3(p +.3);

    // Output to screen
    glFragColor = vec4(col,1.0);
}

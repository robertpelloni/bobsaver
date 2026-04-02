#version 420

// original https://www.shadertoy.com/view/tsXSzn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// color circle part 1

void main(void) {
    // normailze and adjsut for ratio
    vec2 res = resolution.xy,
    uv = (gl_FragCoord.xy*2.0-res ) / res.y;
    
    //initilize colors
    vec4 background = vec4(.2,.7,.7,1.0)*-uv.y*.3*cos(uv.x); 
    vec4 color = vec4(1.0,.7,.2,1.0);
    
    // calculate fragment distance from center
    float d = length(uv*4.0); 
    uv+=uv/d*cos(d-time);
    float shape = .2/length(fract(uv*1.5)-.5);
    color*=shape*uv.y;
    
    //output final color
    glFragColor = mix(background, color, color.a);
}


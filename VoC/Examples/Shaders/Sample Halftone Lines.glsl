#version 420

// original https://www.shadertoy.com/view/MsBfzm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define linesRows 5.0
#define thickness 0.25
#define invert 0

vec2 rotateCoord(vec2 uv, float rads) {
    uv *= mat2(cos(rads), sin(rads), -sin(rads), cos(rads));
    return uv;
}

void main(void)
{
    // update layout params
    float rows = linesRows * 0.5;//linesRows + 3. * sin(time);
    float curThickness = 0.25 + 0.22 * cos(time);
      float curRotation = 0.8 * sin(time);
    // get original coordinate, translate & rotate
    vec2 uv = (2. * gl_FragCoord.xy - resolution.xy) / resolution.y;
    //uv += curCenter;
    uv = rotateCoord(uv, curRotation);
    // create grid coords
    vec2 uvRepeat = fract(uv * rows);        
    // adaptive antialiasing, draw, invert
    float aa = resolution.y * 0.00003;     
    float col = smoothstep(curThickness - aa, curThickness + aa, length(uvRepeat.y - 0.5));
    if(invert == 1) col = 1. - col;            
    glFragColor = vec4(vec3(col),1.0);
}

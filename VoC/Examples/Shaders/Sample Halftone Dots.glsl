#version 420

// original https://www.shadertoy.com/view/MdBfzm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define dotsRows 5.0
#define radius 0.25
#define invert 1

vec2 rotateCoord(vec2 uv, float rads) {
    uv *= mat2(cos(rads), sin(rads), -sin(rads), cos(rads));
    return uv;
}

void main(void)
{
    // update layout params
    float rows = dotsRows + 3. * sin(time);
    float curRadius = radius + 0.15 * cos(time);
      float curRotation = time;
    vec2 curCenter = vec2(cos(time), sin(time));
    // get original coordinate, translate & rotate
    vec2 uv = (2. * gl_FragCoord.xy - resolution.xy) / resolution.y;
    uv += curCenter;
    uv = rotateCoord(uv, curRotation);
    // calc row index to offset x of every other row
    float rowIndex = floor(uv.y * rows);        
    float oddEven = mod(rowIndex, 2.);
    // create grid coords
    vec2 uvRepeat = fract(uv * rows) - 0.5;        
    if(oddEven == 1.) {                            // offset x by half
        uvRepeat = fract(vec2(0.5, 0.) + uv * rows) - vec2(0.5, 0.5);    
    }
    // adaptive antialiasing, draw, invert
    float aa = resolution.y * dotsRows * 0.00001;     
    float col = smoothstep(curRadius - aa, curRadius + aa, length(uvRepeat));
    if(invert == 1) col = 1. - col;            
    glFragColor = vec4(vec3(col),1.0);
}

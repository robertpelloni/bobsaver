#version 420

// original https://www.shadertoy.com/view/Mltfzn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// 2*pi
#define TAU 6.283185307179

vec2 cxmul(vec2 z, vec2 w) {
    return vec2(z.x*w.x - z.y*w.y, z.x*w.y + z.y*w.x);
}

vec2 cxdiv(vec2 z, vec2 w) {
    return cxmul(z, vec2(w.x, -w.y)) / dot(w,w);
}

vec2 mobius(in vec2 z, in vec2 a, in vec2 b, in vec2 c, in vec2 d) {
    return cxdiv(cxmul(a,z) + b, cxmul(c,z) + d); 
}

// mobius transformation described with which complex numbers 
// it sends to zero, one and infinity.
// q -> 0, r -> 1, s -> inf
vec2 mobi3(vec2 z, vec2 q, vec2 r, vec2 s) {
    return cxdiv(cxmul(z - q, r - s), cxmul(z - s, r - q));
}

vec2 rotate(vec2 v, float a) {
  float s = sin(a);
  float c = cos(a);
  mat2 m = mat2(c, -s, s, c);
  return m * v;
}

const float scale = 1.5;

void main(void)
{
     float time = time*0.25;
    
    // centered around origin, [-1, 1];
    vec2 pos = -1.0 + 2.0 * gl_FragCoord.xy / resolution.xy;  
    // 1:1 aspect ratio
    pos.x *= resolution.x/resolution.y;
    
    vec2 zero = vec2( .15, 0.);
    vec2 one =  vec2( -.15, 0.);
    vec2 inf =  vec2( 0., 1.5);

    // mobius transformed position - deforms the plane 
    vec2 posi = mobi3(pos, zero, one, inf);
      
    // switch for the two phases of the animation
    // 0 for 0 < (time % 2) < 1
    // 1 for 1 < (time % 2) < 2 
    float sw = mod(floor(2.*time),2.);

    // make a grid with the inverted position
    // the switch moves the grid for when the visual "switch" happens
    vec2 gposi = -1. + 2. * fract((scale*posi + sw*0.5 - time));
    
    // eased time for smooth rotation anim 
    float eased = 0.5*(1.-cos(mod(time,0.5)*TAU));
    // switch direction for the two phases of the animation
    eased *= mix(1., -1., sw);
    gposi = rotate(gposi, eased*TAU/4.);
    
    // distance function for a 45 degree rotated square, or a diamond
    float diamond = smoothstep(0., 1., (abs(gposi.x)+abs(gposi.y))*0.5);
    
    // this flips the colors of the diamond for the different phases of the anim
    // together with the grid movement, this produced the visual "switch"
    // from black squares on white bg to white squares on black bg
    float switchedDiamond = mix(2.-diamond*2., diamond*2., sw);
    
    // use the distance func to make squares 
    float colVal = pow(switchedDiamond, 20.);
    
    // Output to screen
    glFragColor = vec4(vec3(colVal),1.0);
}

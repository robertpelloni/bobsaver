#version 420

// original https://www.shadertoy.com/view/XtyGD1

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// By Zanzlanz
// Creative commons with attribution, please - Sorry for ugly code btw :)

float exp2Iterations = 4.0; // Gets changed in realtime. Iterations the fragment will calculate.
bool tri(float x, float y) {
    return (x+y < 1.0);
}
// I just needed a bitwise &. Ah well, here's a function that does it:
float and(vec2 n) {
    if(n.x<0.0 || n.y<0.0 || n.x>=exp2Iterations || n.y>=exp2Iterations) return -1.0;
    float bitVal = 1.0;
    float result = 0.0;
    for(int i=0; i<32; i++) {
        if (mod(n.x, 2.0) == 1.0 && mod(n.y, 2.0) == 1.0) result+=bitVal;
        n = floor(n / 2.0);
        bitVal *= 2.0;
        if(!(n.x > 0.0 || n.y > 0.0)) break;
    }
    return result;
}
void main(void) {
    vec2 uv = gl_FragCoord.xy / resolution.y;
    exp2Iterations = exp2( floor(sin(time+uv.y*2.0+uv.x*1.0+1.5+sin(uv.y*15.0)*.05)*4.0+4.5) );
     
    float scale = (sin(time*.4+3.0)*.4+.9)*exp2Iterations; // Pulsating
    
    // Movement around screen
    uv.y -= .3*sin(time*.43) + .5;
    uv.x -= .3*sin(time*.33) + .5+(resolution.x-resolution.y)/resolution.y*.5;
    
    // Use polar coordinates to do funky rotation stuff
    float d = length(uv);
    float r = atan(uv.y, uv.x);
    r += .6+(1.0-d*.5)*sin(time*.3)*3.0;
    uv = vec2(d*cos(r), d*sin(r));
    
    uv*=scale; // Scale it properlyish
    
    // Center on centroid so rotation looks good
    uv.x+=exp2Iterations*.5;
    uv.y+=exp2Iterations*.5/sqrt(3.0);
    
    uv.y/=sqrt(3.0)/2.0; // ...then make it equilateral!
    uv.x-=uv.y*.5;       // Convert graph to isosceles first...
    
    // If x&y==0 and point lies under triangle, we're on the triangle! Woot!
    if(and(floor(uv)) == 0.0 && tri(mod(uv.x, 1.0), mod(uv.y, 1.0)))
         glFragColor = vec4(gl_FragCoord.xy/resolution.xy, 1.0, 1.0);
    else glFragColor = vec4(gl_FragCoord.xy/resolution.xy*.1, 0.1, 1.0);
}

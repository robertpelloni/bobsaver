#version 420

// Competing endless tunnels
// Simplified by @kimonsatan

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;   //normalise coordinates (1,1)

    uv.x -= 0.5; //center coordinates
    uv.y -= 0.5; //center coordinates
    //uv.y *= resolution.y/resolution.x; //correct the aspect ratio
    uv *= 2.0; //scale  
    float po = 2.0; // amount to power the lengths by
    float px = pow(uv.x * uv.x, po); //squaring the values causes them to rise slower creating a square effect
    float py = pow(uv.y * uv.y, po);
    float a =   2.0* atan(uv.y , uv.x) + time/10.0 ; //this makes the checker board but I still don't get why it works with atan
    //float a = 2.0; // uncomment to remove the checker board
    float r = pow( px + py, 1.0/(2.0 * po) );  // convert the vector into a length (pythagoras duh)
    vec2 q = vec2( 1.0/r + time * 0.95 , a ); //flip it so that the bands get wider towards the edge
    
    vec2 l = floor(q*4.6); //scale the values higher to make them into cycling integers
    float c = mod(l.x+l.y, 2.0); // now get the modulo to return values between 0 and 1 (ish)
    c *= pow(r,2.0); // darken everything towards the center

    glFragColor = vec4( c,c,c, 1.0 ); // set the pixel colour

}

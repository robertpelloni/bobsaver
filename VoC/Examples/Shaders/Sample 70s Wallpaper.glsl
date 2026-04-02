#version 420

// original https://www.shadertoy.com/view/ls33DN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*

    70s Wallpaper
    -------------

    2D, square Truchet pattern, in under a tweet. I was looking at Fabrice and JT's
    2D Truchet efforts, and got to wondering just how few characters would be necessary
    to achieve a passable pattern.

    I didn't make a great effort to "code golf" this, because I wanted it to be readable, 
    or at least a little bit. I also prefer to maintain a modicum of accuracy and 
    efficiency. However, I'm sure someone out there could shave off a few characters.

    By the way, just for kicks, I included a slightly obfuscated. one line version below.

    More sophisticated examples:
    
    TruchetFlip - jt // Simple, square tiling.
    https://www.shadertoy.com/view/4st3R7
    
    TruchetFlip2 - FabriceNeyret2 // The checkerboard flip is really clever.
    https://www.shadertoy.com/view/lst3R7

    Twisted Tubes - Shane // 3D Cube Truchet example. Several tweets. :)
    https://www.shadertoy.com/view/lsc3DH

*/

void main(void) {
    
    vec2 p=gl_FragCoord.xy;
    // Screen coordinates. I kind of feel like I'm cheating with the constant divide.
    // 834144373 and iapafoto suggested that I could incorporate the first line into the 
    // line below like so:
    //
    // p.x *= sign(cos(length(ceil(p/=50.))*99.)); 
    // 
    // However, for intuitiveness and compatibility, I'll leave it unchanged, for the time being.
    p /= 50.;
    
    // Randomly flipping the tile, based on its unique ID (ceil(p)), which in turn, is based 
    // on its position. The idea to use "ceil" instead of "floor" came from Fabrice's example.
    p.x *= sign(cos(length(ceil(p))*99.));
    
    // Drawing the tile, which consists of two arcs: tileArc = min(length(p), length(p-1.));
    // Using "cos" to repeat the arcs... more or less: value = cos(tileArc*2*PI*repeatFactor);
    // The figure "44" is approximately PI*2*7, or TAU*7.
    glFragColor = vec4(0.0);
    glFragColor = glFragColor - glFragColor + cos(min(length(p = fract(p)), length(--p))*44.); // --p - Thanks, Coyote.
    
    // Gaudy color, yet still not garish enough for the 70s. :)
    //glFragColor = cos(min(length(p = fract(p)), length(--p))*vec4(1, 3, 3, 1)*12.6);
    
}

/*
// One line version. Also under a tweet.
void main(void) { //WARNING - variables void ( out vec4 o, vec2 p ){ need changing to glFragColor and gl_FragCoord
    
    // Ridiculous (as in stupid) one liner:
    o = o - o + cos(min(length(p = fract(p *= vec2(sign(cos(length(ceil(p/=50.))*99.)), 1))), length(--p))*44.);

}
*/

/*
// More trustworthy version.
void main(void) { //WARNING - variables void ( out vec4 o, in vec2 p ){ need changing to glFragColor and gl_FragCoord

    p /= resolution.y*.1;
    
    p.x *= sign(fract(sin(dot(floor(p), vec2(41, 289)))*43758.5453)-.5);
                
    p = fract(p);
                
    o -= o - cos(min(length(p), length(p - 1.))*6.283*7.);
    
}
*/

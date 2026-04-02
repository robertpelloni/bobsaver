#version 420

// original https://www.shadertoy.com/view/lsX3zM
// the horizontal lines are always level

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

void main(void)
{
    vec2 vCoord = gl_FragCoord.xy / resolution.xy;
    vCoord.x *= resolution.x / resolution.y;
    
    vec2 vTilePos = vCoord * 10.0;
    
    float fScroll = time + 0.25;    
    
    float fIsOddRow = (mod(vTilePos.y, 2.0) > 1.0) ? 0.0 : 1.0;
    vTilePos.x += fScroll * (fIsOddRow * 2.0 - 1.0);
    
    float fShade = (mod(vTilePos.x, 2.0) > 1.0) ? 0.0 : 1.0;    
    
    vec2 vTileFract = fract(vTilePos);    
    
    float fBorderShade = 0.5;
    float fBorderWidth = 0.05;
    fShade = mix(fShade, fBorderShade, step(vTileFract.x, fBorderWidth));
    fShade = mix(fShade, fBorderShade, step(vTileFract.y, fBorderWidth));
    
    glFragColor = vec4(fShade);
}

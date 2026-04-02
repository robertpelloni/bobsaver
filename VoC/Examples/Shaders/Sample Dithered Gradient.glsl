#version 420

// original https://www.shadertoy.com/view/wt2cRz

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//@samzanemesis

float sdCapsule( vec2 p, vec2 a, vec2 b )
{
  vec2 pa = p - a, ba = b - a;
  float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
  return length( pa - ba*h );
}

void main(void)
{
    vec2 vOriginalUV = gl_FragCoord.xy/resolution.y;
    vec2 uv = vOriginalUV * 10.0;
    if( mod(uv.y, 2.0) > 1.0 )
        uv.x -= 0.5;
    uv = mod(uv, vec2(2.0, 1.0));
    
    //We make the geometry here
    
    //Line
    float fGeo = 0.0;
    float fLine = sdCapsule( uv, vec2(0.1,0.1), vec2(0.9,0.9));
    fLine = min(sdCapsule( uv, vec2(0.9,0.1), vec2(0.1,0.9)),fLine);
    //Dots
    float fDots = distance(uv, vec2(1.25,0.25));
    fDots = min(distance(uv, vec2(1.75,0.25)), fDots);
    fDots = min(distance(uv, vec2(1.75,0.75)), fDots);
    fDots = min(distance(uv, vec2(1.25,0.75)), fDots);
    
    //And we merge them
    fGeo = min(fLine,fDots);
    
    //Here we set how much we are fading from 0 to 1
    //Obviously in code you set this to something else like depth :)
    float fFadeAnimation = sin( time + vOriginalUV.y );
    
    float fFade = 0.0;
    
    if( fGeo > fFadeAnimation )
        fFade = 1.0;

    // Time varying pixel color
    vec3 col = vec3(fFade,fFade,fFade);
    // Output to screen
    glFragColor = vec4(col,1.0);
}

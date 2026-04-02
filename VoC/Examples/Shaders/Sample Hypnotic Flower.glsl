#version 420

// original https://www.shadertoy.com/view/WdSBWD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

        
vec3 palette( float t, vec3 a, vec3 b, vec3 c, vec3 d )
{
    return a + b * cos( 2.*3.14159 * ( c * t + d) );
}

vec3 MyPalette1( float t )
{
    return palette( t, vec3(.8, .5, .4), vec3(.2,.4,.2), vec3( .5), vec3( 0., .25, .25));
}
vec3 MyPalette2( float t )
{
    return palette( t, vec3(.5, .5, 5), vec3(.5, .5, .5), vec3( 1., 0.7,0.4), vec3( 0., .15, .2));
}
vec3 MyPalette3( float t )
{
    return palette( t, vec3(.5), vec3(.5), vec3( 1.), vec3( 0.3, .2, .2));
}
vec3 MyPalette4( float t )
{
    return palette( t, vec3(.5), vec3(.5), vec3( 1.,1.,0.5), vec3( 0.8, .9, .3));
}
vec3 MyPalette5( float t )
{
    return palette( t, vec3(.8, .5, .4), vec3(.2), vec3( .5,.5,0.5), vec3( 0., .9, .3));
}

// nice palettes from shane :
vec3 MyPalette6(float t )
{
    return .8 + .2*cos(6.3*t + vec3(0, 23, 21));
}
vec3 MyPalette7(float t )
{
    return .5 + .4*cos(6.3*t + vec3(2, 1, 0));
}
vec3 MyPalette8(float t )
{
    return .6 + .4*cos(6.*t + vec3(5, 3, 1));
}
    // Etc.
    //vec3 col = .5 + .4*cos(6.3*h21(d.yz) + vec3(2, 1, 0));
    //vec3 col = .6 + .4*cos(6.*h21(d.yz) + vec3(5, 3, 1));

vec3 Flower( vec2 uv, float paletteShift )
{
    vec2 st = vec2( atan(uv.x, uv.y), length(uv ) );
    uv = vec2( st.x/3.14159 + time*.2, st.y);

    float myX = mod (uv.x, .2) -.1;
    float func = -5.*myX * myX + .2;
    float val = func - uv.y;
    
    val = smoothstep( 0., 0.01, val);

    return val * MyPalette1(uv.y*7. + paletteShift);
}

vec3 Flower2( vec2 uv, float paletteShift )
{
    vec2 st = vec2( atan(uv.x, uv.y), length(uv ) );
    uv = vec2( st.x/3.14159 + time*.2, st.y);

    float myX = mod (uv.x, .2) -.1;
    float func = -10.*myX * myX + .2;
    float val = func - uv.y;
    
    val = smoothstep( 0., 0.01, val);

    return val * MyPalette3(uv.y*7. + paletteShift);
}

vec3 flowersField1( vec2 uv)
{
    uv = mod( uv, .5 ) - 0.25;
    vec3 col = vec3(0);
    
    float fact = 1.;
    float paletteShift = 0.;
    for ( int i = 0; i < 10; i++)
    {
        vec3 flowerCol = Flower(uv * fact, paletteShift);
        if ( length(flowerCol) > 0.)
            col = flowerCol;
        fact *= 1.1;
        paletteShift += 1.5 + time*0.1;
                
    }
    return col;
}
vec3 flowersField2( vec2 uv)
{
    uv = mod( uv, .5 ) - 0.25;
    vec3 col = vec3(0);
    
    float fact = 1.;
    float paletteShift = 0.;
    for ( int i = 0; i < 10; i++)
    {
        vec3 flowerCol = Flower2(uv * fact, paletteShift);
        if ( length(flowerCol) > 0.)
            col = flowerCol;
        fact *= 1.1;
        paletteShift += 1.5 + time*0.1;
                
    }
    return col;
}
mat2 rot( float a )
{
    float c = cos(a);
    float s = sin(a);
    return mat2( c, s, -s, c);
}
vec2 moveUV( vec2 uv, float angle, float zoom, vec2 dep )
{
    return rot( angle ) * ( ( uv * zoom) + dep );
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv  = (uv - .5)*2.;
    uv.x  *= resolution.x / resolution.y;
    
    vec2 realUv = uv;
    vec3 col = length(uv*.3) *vec3(0.3,0.3,0.8);

    // general camera move :
    uv = moveUV( uv, sin(time*.2), .28+.13*sin(time*.51), vec2(cos(time*.001), sin(time*.00039)));

    
    
    float fact = 1.;
    const float factInc = 1.3;
    for( float i = 0.; i < 2.; i+=1.)
    {
        vec2 p = moveUV( uv, sin(time*.2), fact, vec2(cos(time*.011), sin(time*.007)));
        vec3 flower1 = flowersField1(p);
        if (length(flower1) > 0. )
            col = flower1;
        p = moveUV( uv, sin(time*.2), fact*factInc, vec2(cos(time*.001), sin(time*.007)));
        vec3 flower2 = flowersField2(p*fact*factInc);
        if (length(flower2) > 0. )
            col = flower2;
        fact = fact * factInc * factInc;
        
    }
    
    // Output to screen
    col*=smoothstep(2.,1.,length(realUv));
    glFragColor = vec4(col,1.0);
}

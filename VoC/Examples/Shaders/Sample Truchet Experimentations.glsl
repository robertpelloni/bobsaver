#version 420

// original https://www.shadertoy.com/view/3s2fR1

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float hash21(vec2 p)
{
    float v = fract(sin( p.x*1234.68 + p.y * 98765.543)*753.159);
    return v;
}

vec3 palette( float t, vec3 a, vec3 b, vec3 c, vec3 d )
{
    return a + b * cos( 2.*3.14159 * ( c * t + d) );
}

// Different tries with palettes :
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

vec3 MyPalette( float t )
{
    return MyPalette3(t);
}

float full_width = 0.09;
float fade_width = 0.1;

vec3 insideBoxDraw2( vec2 uv )
{
    vec3 col;
    float d = min( abs(uv.x), abs(uv.y));
    float val = smoothstep( fade_width, 0.,  d - full_width);
    col = vec3(val);
    return col;
}
vec3 insideBoxDraw3( vec2 uv )
{
    vec3 col;
    float d = abs(abs(uv.x + uv.y) -.5);
    float val = smoothstep( fade_width, 0.,  d - full_width);
    col = vec3(val);
    return col;
}

vec3 circle( vec2 uv, vec2 center, float rad, float width, vec3 color )
{
    float d = length(uv - center );
    float val = smoothstep(  fade_width, 0., abs( d-rad) - full_width );
    return val * color;
}

vec3 insideBoxDraw( vec2 uv )
{
    vec3 col = vec3(0.);
    
    vec2 center = vec2(.5,.5);
    vec2 center2 = vec2(-.5,-.5);
    
    col  = circle( uv, center, .5, 0.05, vec3( 1.,1.,1.));
    col += circle( uv, center2, .5, 0.05, vec3( 1.,1.,1.));
    return col;
}

float truchet(vec2 p )
{
    float returnVal = 0.;
    
    vec2 boxCoord = fract(p)-.5;
    vec2 id = floor(p);
    
    
    //col = vec3( 1.-length(boxCoord) );
    
    float rnd = hash21( id );
    if ( rnd < .5)
        boxCoord.x = -boxCoord.x;
    
    float rnd2 = mod(rnd, .5 ) * 2.; 
    if ( rnd2 < .33)
        returnVal = insideBoxDraw2(boxCoord).x;
    else
        if ( rnd2 < .66)
            returnVal = insideBoxDraw(boxCoord).x;
        else
            returnVal = insideBoxDraw3(boxCoord).x;
        
     
    return returnVal;    
    /*
    if ( boxCoord.x > 0.48 || boxCoord.y > 0.48 )
        col = vec3(1., 0.,0.);
    //*/
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
    vec2 uv = gl_FragCoord.xy/resolution.xy * 2. - 1.;
    uv.x *= resolution.x/resolution.y;

    vec2 realUv = uv;
    vec3 col = length(uv*.3) *vec3(0.3,0.3,0.8);

    // general camera move :
    uv = moveUV( uv, sin(time*.2), 1.1+.2*sin(time*.51), vec2(cos(time*.1), sin(time*.07)));
    
    float nbLayers = 10.;
    for( float i = 0.; i < nbLayers; i+= 1.)
    {
        vec2 coord = moveUV( uv, time/(.3*i+1.), (nbLayers-i)*2., (nbLayers-i)*vec2(cos(time*5./(i+1.)), sin(time*3./(i+1.))) );
        float truchetVal = truchet(coord);
        
        
        float timeFactorPal = .5;
        vec3 paletteColor1= mix( MyPalette1( length(coord )*2.), MyPalette5( length(coord )*.5), .5+.5*sin(time*timeFactorPal)) ;
        vec3 paletteColor2 = mix( MyPalette1( length(coord )*2.), MyPalette3( length(coord )*3.), .5+.5*sin(time*timeFactorPal)) ;
        
        //vec3 paletteColor = mix( paletteColor1, paletteColor2, i/nbLayers);
        vec3 paletteColor = paletteColor1;
    
        vec3 layerCol = paletteColor * ( i) / nbLayers;
        col = mix( col,  layerCol, truchetVal);
    }
    
    // Output to screen
    //vignetting :
    col*=smoothstep(2.5,1.,length(realUv));
    
    glFragColor = vec4(col,1.0);
}

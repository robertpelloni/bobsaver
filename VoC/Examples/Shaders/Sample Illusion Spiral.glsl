#version 420

// original https://www.shadertoy.com/view/ftyyWR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Illusion based on https://twitter.com/Rainmaker1973/status/1561322229559726080

const bool grey_bars = false;

vec3 CalcColor( vec2 uvz )
{

    bool showdiamonds = true; //fract(time*0.1)>0.5;
    
    // THIS LINE is really cool.  The diamonds are what are **the key** to this illusion.
    bool checkdiamonds = true;// fract(time*0.1)>0.5;   //XXX HEY, YOU!!! PLAY WITH TURNING THIS ON AND OFF.
    
    float spin_speed = 0.15;
    float zoom_speed = 0.3;
    const float segpairs = 18.0;
    
    vec2 thetar = vec2(atan( uvz.x, uvz.y ), length( uvz ) );

    const float PI = 3.14159265;
    const float TAU = PI * 2.0;
    
    thetar.x += PI;
    
    thetar.x += time*spin_speed;
    
    float segno;
    float segplace = (thetar.x * segpairs / TAU);
    segplace = modf( segplace, segno );

    // For debugging
    //return vec3( thetar.y );
    float oneoverr = mix( 40.0, 1.0, pow( 1.0/thetar.y, 0.07) );
    oneoverr += 0.5;
    
    
    oneoverr += time * zoom_speed;
    
    float oneoverrf = fract( oneoverr );

    // Neat effect.
    //return vec3( min( fract(segplace + oneoverrf), fract(segplace - oneoverrf) ) );

    float diamondmr = fract(oneoverrf*2.0);
    float diamondms = fract(segplace*2.0);
    float diamondr = abs(0.5-diamondmr);
    float diamonds = abs(0.5-fract(diamondms+diamondmr));
    float diamondp = abs(0.5-fract(diamondms));
    float diamondt = abs(0.5-fract(diamondms-diamondmr));
    float diamondinten = min( min( diamondr, diamonds ), min( diamondp, diamondt ) );

    // Uncomment for another neat effect.
    //return vec3(  min( diamondr, diamonds ) );

    float offset = floor(fract(oneoverr/2.0)*2.0)*0.5;
    // For debugging
    //return vec3( offset) ;

    vec3 col = vec3( 1.0 );
    
    if( diamondinten > 0.17 && showdiamonds )// duva > 0.0 )
    {
        col = vec3((diamondr-diamondp)>0.0);
        // Uncomment for a neat shape.
        //return vec3( abs(  0.5 - segplace  )>0.25);
        if( !checkdiamonds ) 
            segplace = 0.0;
            
        if( (fract(oneoverr*0.5+0.4)>0.5) ^^ ( fract( abs( 0.5 - segplace ) ) > 0.25 ) )
            col = 1.0-col;
    }
    else
    {
        if( oneoverrf < 0.5 )
        {
            col = (fract( segplace + offset ) > 0.5)?vec3( 1.0, 1.0, 1.0 ):vec3( 0.0, 0.0, 0.0 );
        }
        else
        {
           col = (fract( segplace + offset + 0.25 ) > 0.5)?vec3( 0.1, 0.6, 1.0 ):vec3( 0.1, 1.0, 1.0 );
        }
    }
    return col;
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    vec2 uvz = uv * 2. - 1.;
    
    // Grey bars on the sides.
    if( grey_bars )
        if( uvz.x < -resolution.y/resolution.x || uvz.x > resolution.y/resolution.x ) { glFragColor = vec4( 0.5); return; }
    
    // Make it square.
    uvz.x *= resolution.x/resolution.y;
 
    vec3 col = vec3( 0.0 );
    float count = 0.0;
    
    // Anti-alias it to mush.
    vec2 uvofsl = vec2(1.3/resolution.xy);
    vec2 ofs = -uvofsl;
    for( ; ofs.x <= uvofsl.x; ofs.x += uvofsl.x*0.3 )
    {
        for( ofs.y = -uvofsl.y; ofs.y <= uvofsl.y; ofs.y += uvofsl.y*0.3 )
        {
            col += CalcColor( uvz+ofs );
            count ++;
        }
    }
    
    // Output to screen
    glFragColor = vec4(col/count,1.0);
}

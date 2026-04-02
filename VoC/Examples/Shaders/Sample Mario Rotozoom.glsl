#version 420

// original https://www.shadertoy.com/view/Wl2cWt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define SPRITE_DEC( x, i )     mod( floor( i / pow( 4.0, mod( x, 8.0 ) ) ), 4.0 )
#define RGB( r, g, b ) vec3( float( r ) / 255.0, float( g ) / 255.0, float( b ) / 255.0 )
#define pi 3.14159265

void SpriteMario( inout vec3 color, float x, float y, float frame )
{    
    float idx = 0.0;

    if ( frame == 0.0 )
    {
        idx = y == 14.0 ? ( x <= 7.0 ? 40960.0 : 42.0 ) : idx;
        idx = y == 13.0 ? ( x <= 7.0 ? 43008.0 : 2730.0 ) : idx;
        idx = y == 12.0 ? ( x <= 7.0 ? 21504.0 : 223.0 ) : idx;
        idx = y == 11.0 ? ( x <= 7.0 ? 56576.0 : 4063.0 ) : idx;
        idx = y == 10.0 ? ( x <= 7.0 ? 23808.0 : 16255.0 ) : idx;
        idx = y == 9.0 ? ( x <= 7.0 ? 62720.0 : 1375.0 ) : idx;
        idx = y == 8.0 ? ( x <= 7.0 ? 61440.0 : 1023.0 ) : idx;
        idx = y == 7.0 ? ( x <= 7.0 ? 21504.0 : 793.0 ) : idx;
        idx = y == 6.0 ? ( x <= 7.0 ? 22272.0 : 4053.0 ) : idx;
        idx = y == 5.0 ? ( x <= 7.0 ? 23488.0 : 981.0 ) : idx;
        idx = y == 4.0 ? ( x <= 7.0 ? 43328.0 : 170.0 ) : idx;
        idx = y == 3.0 ? ( x <= 7.0 ? 43584.0 : 170.0 ) : idx;
        idx = y == 2.0 ? ( x <= 7.0 ? 10832.0 : 42.0 ) : idx;
        idx = y == 1.0 ? ( x <= 7.0 ? 16400.0 : 5.0 ) : idx;
        idx = y == 0.0 ? ( x <= 7.0 ? 16384.0 : 21.0 ) : idx;
    }
    else if ( frame == 1.0 ) 
    {
        idx = y == 15.0 ? ( x <= 7.0 ? 43008.0 : 10.0 ) : idx;
        idx = y == 14.0 ? ( x <= 7.0 ? 43520.0 : 682.0 ) : idx;
        idx = y == 13.0 ? ( x <= 7.0 ? 54528.0 : 55.0 ) : idx;
        idx = y == 12.0 ? ( x <= 7.0 ? 63296.0 : 1015.0 ) : idx;
        idx = y == 11.0 ? ( x <= 7.0 ? 55104.0 : 4063.0 ) : idx;
        idx = y == 10.0 ? ( x <= 7.0 ? 64832.0 : 343.0 ) : idx;
        idx = y == 9.0 ? ( x <= 7.0 ? 64512.0 : 255.0 ) : idx;
        idx = y == 8.0 ? ( x <= 7.0 ? 25856.0 : 5.0 ) : idx;
        idx = y == 7.0 ? ( x <= 7.0 ? 38208.0 : 22.0 ) : idx;
        idx = y == 6.0 ? ( x <= 7.0 ? 42304.0 : 235.0 ) : idx;
        idx = y == 5.0 ? ( x <= 7.0 ? 38208.0 : 170.0 ) : idx;
        idx = y == 4.0 ? ( x <= 7.0 ? 62848.0 : 171.0 ) : idx;
        idx = y == 3.0 ? ( x <= 7.0 ? 62976.0 : 42.0 ) : idx;
        idx = y == 2.0 ? ( x <= 7.0 ? 43008.0 : 21.0 ) : idx;
        idx = y == 1.0 ? ( x <= 7.0 ? 21504.0 : 85.0 ) : idx;
        idx = y == 0.0 ? ( x <= 7.0 ? 21504.0 : 1.0 ) : idx;
    }
    else if ( frame == 2.0 ) 
    {
        idx = y == 15.0 ? ( x <= 7.0 ? 43008.0 : 10.0 ) : idx;
        idx = y == 14.0 ? ( x <= 7.0 ? 43520.0 : 682.0 ) : idx;
        idx = y == 13.0 ? ( x <= 7.0 ? 54528.0 : 55.0 ) : idx;
        idx = y == 12.0 ? ( x <= 7.0 ? 63296.0 : 1015.0 ) : idx;
        idx = y == 11.0 ? ( x <= 7.0 ? 55104.0 : 4063.0 ) : idx;
        idx = y == 10.0 ? ( x <= 7.0 ? 64832.0 : 343.0 ) : idx;
        idx = y == 9.0 ? ( x <= 7.0 ? 64512.0 : 255.0 ) : idx;
        idx = y == 8.0 ? ( x <= 7.0 ? 42320.0 : 5.0 ) : idx;
        idx = y == 7.0 ? ( x <= 7.0 ? 42335.0 : 16214.0 ) : idx;
        idx = y == 6.0 ? ( x <= 7.0 ? 58687.0 : 15722.0 ) : idx;
        idx = y == 5.0 ? ( x <= 7.0 ? 43535.0 : 1066.0 ) : idx;
        idx = y == 4.0 ? ( x <= 7.0 ? 43648.0 : 1450.0 ) : idx;
        idx = y == 3.0 ? ( x <= 7.0 ? 43680.0 : 1450.0 ) : idx;
        idx = y == 2.0 ? ( x <= 7.0 ? 2708.0 : 1448.0 ) : idx;
        idx = y == 1.0 ? ( x <= 7.0 ? 84.0 : 0.0 ) : idx;
        idx = y == 0.0 ? ( x <= 7.0 ? 336.0 : 0.0 ) : idx;
    }

    idx = SPRITE_DEC(x, idx);
    
    color = idx == 1.0 ? RGB(106, 107, 4) : color;
    color = idx == 2.0 ? RGB(177, 52, 37) : color;
    color = idx == 3.0 ? RGB(227, 157, 37) : color;    
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    vec2 spritepos = gl_FragCoord.xy;
    spritepos = (spritepos - resolution.xy/2.0) * 0.25*(sin(1.5*time) + 1.2);
    float a = mod(time, 2.0*pi);
    spritepos = vec2(spritepos.x*cos(a)-spritepos.y*sin(a),spritepos.x*sin(a)+spritepos.y*cos(a));
    spritepos = floor(mod(spritepos,16.0));

    // Time varying pixel color
    vec3 col = vec3(0.0);
    
    SpriteMario(col, spritepos.x, spritepos.y, floor(mod(8.0*time,3.0)));

    // Output to screen
    glFragColor = vec4(col,1.0);
}

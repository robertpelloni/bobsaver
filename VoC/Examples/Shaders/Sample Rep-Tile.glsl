#version 420

// original https://www.shadertoy.com/view/X33XW2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float PLASTIC = 1.324717957244746;
const float PLASTIC_2 = pow( PLASTIC, 2. );
const float PLASTIC_3 = pow( PLASTIC, 3. );
const float PLASTIC_4 = pow( PLASTIC, 4. );
const float PLASTIC_5 = pow( PLASTIC, 5. );
const float PLASTIC_6 = pow( PLASTIC, 6. );
const float PLASTIC_7 = pow( PLASTIC, 7. );
const float PLASTIC_8 = pow( PLASTIC, 8. );
const float PLASTIC_9 = pow( PLASTIC, 9. );

const vec2 HEX0 = vec2( 1., 0. );
const vec2 HEX1 = vec2( .5, sqrt( .75 ) );
const mat2 TO_HEX0_HEX1 = inverse( mat2( HEX0, HEX1 ) );

// a copy of the "original" tile appears as a subtile scaled by pow( PLASTIC, -8. )
// the offset of the scaled copy is at RECURSE_PT
const vec2 RECURSE_PT = vec2( PLASTIC_7 - PLASTIC_3, PLASTIC_3 );
// if we keep repeating the process of finding a scaled version of the "original" tile
// we converge on the FIXED_PT
const vec2 FIXED_PT = mix( RECURSE_PT, vec2( 0. ), -1./(PLASTIC_8-1.) );

// shape of the tile
bool inTile( vec2 h ) // h is in hex coords
{
    if ( h.y < 0. ) return false;   
    if ( h.x < 0. ) return false;
    if ( h.x + h.y > PLASTIC_9 ) return false;  
    if ( h.x + h.y > PLASTIC_8 && h.x < PLASTIC_6 ) return false;
    return true;
}

// map subtile -> parent tile
vec2 fromBigTile( vec2 h )
{
    return h.yx * PLASTIC;
}
// map subtile -> parent tile
vec2 fromMediumTile( vec2 h )
{
    return mat2( 0., -1., 1., -1. ) * (h - vec2(PLASTIC_9, 0.)) * PLASTIC_2;
}
// map subtile -> parent tile
vec2 fromSmallTile( vec2 h )
{
    return mat2( -1., 1., 0., 1. ) * (h - vec2(PLASTIC_7, 0.)) * PLASTIC_4;
}

const int NO_TILE = -1;
const int SMALL_TILE = 0;
const int MEDIUM_TILE = 1;
const int BIG_TILE = 2;
vec2 substitution( vec2 h, out int tileType )
{
    vec2 hh;
    hh = fromBigTile( h );    if ( inTile( hh ) ) { tileType = BIG_TILE;    return hh; }
    hh = fromMediumTile( h ); if ( inTile( hh ) ) { tileType = MEDIUM_TILE; return hh; }
    hh = fromSmallTile( h );  if ( inTile( hh ) ) { tileType = SMALL_TILE;  return hh; }
    tileType = NO_TILE;  
    return h;
}

vec3 colorForTile( int tileType )
{
    if ( tileType == BIG_TILE ) return vec3( 1., 0., 0. );
    if ( tileType == MEDIUM_TILE ) return vec3( 0., 1., 0. );
    if ( tileType == SMALL_TILE ) return vec3( 0., 0., 1. );
    return vec3( 0., 0., 0. );
}

// tile size
float zoom( int tileType )
{
    if ( tileType == BIG_TILE ) return 1.;
    if ( tileType == MEDIUM_TILE ) return 2.;
    if ( tileType == SMALL_TILE ) return 4.;
    return 999.;
}

// 
float bump( float x )
{
    return smoothstep( -2., 5., abs( x ) ) - smoothstep( 5., 32., abs( x ) );
}

vec3 go( vec2 h, float viewportZoom )
{       
    vec3 color = vec3( 0. );
    int tileType;    
    
    float totalZoom = viewportZoom;

    float colorScale = 1.;
    while ( totalZoom < 50. )
    {    
        h = substitution( h, tileType );
        color += colorForTile( tileType ) * bump( totalZoom ) * .15 * mix( 2., 0.2, totalZoom/20. );
        totalZoom += zoom( tileType );
    }
        
    return color;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy*2.-resolution.xy)/resolution.y;
    

    vec2 h = TO_HEX0_HEX1 * uv;
    
    //float t = sin( time * 5. ) * .1; // test seamless looping
    float t = time;
    float viewportZoom = mod( t * 1.0, 4. ) * -2. - 16.;
    
    h *= pow( PLASTIC, viewportZoom );
    h += FIXED_PT;    
    
    vec3 col = go( h, viewportZoom );    
        
    glFragColor = vec4(col,1.0);
}

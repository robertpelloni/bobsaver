#version 420

// original https://www.shadertoy.com/view/ldjXz1

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;

out vec4 glFragColor;

// Reference
// https://www.shadertoy.com/view/MdBGRm
// https://www.shadertoy.com/view/4dX3zl

float sdSphere(in vec3 p, in float d )
{
    return length( p ) - d; 
} 

float sdTorus( in vec3 p, in vec2 t )
{
  vec2 q = vec2( length( p.xz ) - t.x, p.y );
  return length( q ) - t.y;
}

float map( in vec3 p)
{
    return min( sdSphere( p, 1.0 ), sdTorus( p, vec2( 1.5, 0.25 ) ) );
}

vec2 rotate( in vec2 p, in float t )
{
    return p * cos( -t ) + vec2( p.y, -p.x ) * sin( -t );
}   

vec3 rotate( in vec3 p, in vec3 t )
{
    p.yz = rotate( p.yz, t.x );
    p.zx = rotate( p.zx, t.y );
    p.xy = rotate( p.xy, t.z );
    return p;
}

void main( void )
{
    vec2 p = ( 2.0 * gl_FragCoord.xy - resolution.xy ) / resolution.y;
    vec3 rd =normalize( vec3( p, -1.8 ) );
    vec3 ro = vec3( 0.0, 0.0, 3.0 );
    vec3 rot = vec3( 0.5, time * 0.3, time * 0.2 );
    ro = rotate( ro, rot );
    rd = rotate( rd, rot );       
    float s = 0.02;
    ro /= s;
      vec3 grid = floor( ro );
    vec3 grid_step = sign( rd );
    vec3 delta = ( grid + 0.5 * (grid_step + 1.0) - ro ) / rd;    
    vec3 delta_step = abs( 1.0 / rd );
    vec3 mask=vec3(0.0);
    bool hit = false;
    for ( int i = 0; i < 512; i++ )
    {
        if ( map( ( grid + 0.5 ) * s ) < 0.0 ) 
           {
               hit = true;
               break;
        }
        vec3 c = step( delta, delta.yzx );
        mask = c * ( 1.0 - c.zxy );
        grid += grid_step * mask;        
        delta += delta_step * mask;
    }
    vec3 col = vec3( 0.4 + 0.15 * p.y );
    if ( hit )
    {
        col =  vec3( 0.6, 0.8, 1.0 );
        col *= dot( vec3( 0.5, 0.9, 0.7 ), mask );
    }
    glFragColor = vec4( col, 1.0 );
}

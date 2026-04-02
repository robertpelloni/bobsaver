#version 420

// original https://www.shadertoy.com/view/4dV3DK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float pattern( vec3 p )
{
    p = mod( p, vec3( 32.0,32.0, 32.0) );    
    float sum = 0.0;
    for( float i = 4.0; i > 0.0;i--)
    {
        float e = pow( 2.0, i );
        float v = 0.0;
        if ( floor( p.x / e ) > 0.0 )
        {
            v++;
        }
        if ( floor( p.y / e ) > 0.0 )
        {
            v++;
        }
        if ( floor( p.z / e ) > 0.0 )
        {
            v++;
        }
        
         sum += e * mod(v,2.0); 
       
    }
    
    return sum / 32.0;
}

vec4 march2( vec3 start, vec3 ray )
{
    vec4 colour;
    for ( int i = 0; i < 512; i++ )
    {
     
        vec3 p = start;
      
        if ( p.y < -50.0 || 
             p.y > 50.0  )
        {   
             float value = pattern( vec3( p.x,p.z,p.y ));
             return vec4( 0.0, value, value, 1.0 );
        
        }
        
        else if (  mod( floor(p.x/40.0), 2.0) > 0.0 && 
                   mod( floor(p.z/40.0), 2.0 )> 0.0 )
            {
                float value = pattern( p );
                return vec4( value, 0, 0, 1.0 );
       
            }
        
        start += ray;
    }
    
    return vec4(0,0,0,1.0);
}

vec4 march( vec3 start, vec3 ray )
{
    vec4 colour;
    for ( int i = 0; i < 1024; i++ )
    {
        float fog = (1.0 - ( float(i) / 1024.0 ));
     
        vec3 p = start;
      
        if ( p.y < -50.0 || 
             p.y > 50.0  )
        {   
             float value = pattern( vec3( p.x,p.z,p.y ));
             return (vec4( 0.0, value, value, 1.0 ) * 0.5 +
                     march2( p + vec3(0,-ray.y, 0), vec3( ray.x, -ray.y, ray.z) ) * 0.5 ) * fog;
        
        }
        
       else if (  mod( floor(p.x/40.0), 2.0) > 0.0 && 
                   mod( floor(p.z/40.0), 2.0 )> 0.0 )
            {
                float value = pattern( p );
                return vec4( value, 0, 0, 1.0 ) * fog;
       
            } 
        
        start += ray;
    }
    
    return vec4(0,0,0,1.0);
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    float aspect = resolution.y / resolution.x;
    float angle = time;
    vec3 m0 = vec3( cos( angle), 0, -sin(angle));
    vec3 m1 = vec3( 0,1.0,  0 );
    vec3 m2 = vec3( sin( angle), 0, cos(angle) );
    vec3 local = vec3( uv.x - 0.5, (uv.y - 0.5) * aspect, 0.5);
    vec3 ray = vec3( dot( local, m0 ), dot( local, m1 ), dot(local,m2)  );
    //ray =  vec3( 0.5, uv.y - 0.5, uv.x - 0.5 );
    vec3 origin = vec3( 2.0 + cos( time ) * 0.2, sin( time ) * 4.0, time * 10.0 );
    vec3 pos = origin; //+ ray; //vec3( uv.x - 0.5, uv.y - 0.5, 0 );
    float value = 0.0;
    vec4 colour;

    
    glFragColor = march( pos * 10.0, ray * 10.0  * 1.0/16.0);
}

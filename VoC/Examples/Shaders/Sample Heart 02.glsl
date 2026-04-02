#version 420

// mods by NRLABS 2016

uniform float time;
uniform vec2 resolution;

out vec4 glFragColor;

float H( float x,float y )
{
    float d = (x * x) + (y * y) - 1.0;
    return  x * x * y * y * y - d * d * d;
}

void main( void ) 
{
    
    vec2 uv = ( gl_FragCoord.xy / resolution.xy ) * 2.0 - 1.0;
    uv.x *= resolution.x/resolution.y;
    
    float t4 = sin( time ); // ( -1...+1)
    
    uv *= (t4 * t4 + 1.0) * 2.0;
    
    float h = H(uv.x,uv.y);
    
    float hx = H(uv.x + 0.2, uv.y);
    
    float hy = H(uv.x, uv.y - 0.2);
    
    vec3 v = normalize(vec3(hx - h, hy - h, 1.0));
    
    vec3 l = normalize(vec3(1.0, 1.0, 1.0));
    
    float s = pow( dot(v,l), 5.0 );
    
    if( h > 0.0 )
    {
        glFragColor=vec4(mix(vec3(1,0,0),vec3(1,1,1),s),1);
    }
}

#version 420

// original https://www.shadertoy.com/view/3sVGRV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// iq's colouring function
vec3 pal( in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d )
{
    return a + b*cos( 6.28318*(c*t+d) );
}

void main(void)
{
    float t = time / 4.0;
    vec2 pos = gl_FragCoord.xy/resolution.x - vec2( 0.5, 0.5 );
    pos = pos *1.8; 
    pos = pos -vec2( 0.0, -1.7 );
    vec2 c = vec2( -1.12443+cos(t)/29.0, -0.12918 + sin( t ) / 20.0 );
    int idx=0;
    for( idx=0; idx<200;idx++ ) 
    {
        pos = vec2( abs(pos.x), abs( pos.y ) );
        float m = pos.x*pos.x + pos.y*pos.y;
        pos = pos / m + c;
        if( length( pos ) > 4.651232034 ) {
            break;
        }
    }    
    float ints = float(idx) / 200.0;
       vec3 col = pal( ints, vec3(0.5,0.5,0.5),vec3(0.5,0.5,.5),vec3(1.0,0.7,0.4),vec3(0.0,0.15,0.20) );
    glFragColor = vec4(col,1.0);
}

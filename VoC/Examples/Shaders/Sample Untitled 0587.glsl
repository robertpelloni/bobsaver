#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// helpers

float random(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

// noise
float noise( in vec2 p)
{
    
    p*=2.8; // noise intensity
    vec2 i = floor( p );
    vec2 f = fract( p );
    vec2 u = f*f*(3.0-2.0*f);
    return mix( mix( random( i + vec2(0.0,0.0) ), 
                     random( i + vec2(1.0,0.0) ), u.x),
                mix( random( i + vec2(0.0,1.0) ), 
                     random( i + vec2(1.0,1.0) ), u.x), u.y);
}
float fbm( in vec2 uv ){    
    uv *= 5.0;
    mat2 m = mat2( 1.6,  1.2, -1.2,  1.6 );
    float f  = 0.5000*noise( uv ); uv = m*uv;
    f += 0.2500*noise( uv ); uv = m*uv;
    f += 0.1250*noise( uv ); uv = m*uv;
    f += 0.0625*noise( uv ); uv = m*uv;
    f = 0.5 + 0.5*f;
    return f;
}

vec3 bg(vec2 uv )
{
    vec3 bgcolor = vec3(0.01, 0.45, 0.1);
    float velocity = time/2.6;
    float intensity = sin(uv.x*3.+velocity*2.)*1.1+1.5;
    uv.y -= 2.;
    vec2 bp = uv;
    uv *= .6;
    //ripple
    float rb = fbm(vec2(uv.x*.5-velocity*.03, uv.y))*.1;
    //rb = sqrt(rb); 
    uv += rb;
    //coloring
    float rz = fbm(uv*.9+vec2(velocity*.35, 0.0));
    rz *= dot(bp*intensity,bp)+1.2;
    vec3 col = bgcolor/(.1-rz);
    return sqrt(abs(col));
}

void main( void ) {

    vec2 p = ( gl_FragCoord.xy / resolution.xy );
    vec3 color = bg(p)*(2.-abs(p.y*2.));
    glFragColor = vec4( vec3( color), 1.0 );

}

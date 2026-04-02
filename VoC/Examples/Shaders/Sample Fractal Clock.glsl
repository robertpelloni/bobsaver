#version 420

// original https://www.shadertoy.com/view/tlKfzK

uniform float time;
uniform vec4 date;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define kDepth 10
#define kBranches 2
#define kMaxDepth 1024 // kBranches ^ kDepth

//--------------------------------------------------------------------------

mat3 matRotate(float angle)
{
    float c = cos(angle);
    float s = sin(angle);
    return mat3( c, s, 0, -s, c, 0, 0, 0, 1);
}

mat3 matTranslate( float x, float y )
{
    return mat3( 1, 0, 0, 0, 1, 0, -x, -y, 1 );
}

float sdBranch( vec2 p, float w1, float w2, float l )
{
    float h = clamp( p.y/l, 0.0, 1.0 );
    float d = length( p - vec2(0.0,l*h) );
    return d - mix( w1, w2, h );
}

//--------------------------------------------------------------------------

vec3 map( vec2 pos )
{
    const float len = 3.2;
    const float wid = 0.3;
    const float lenf = 0.6;
    const float widf = 0.4;
    
    
    // get time
    float time = date.w;
    float mils = fract(time);
    float secs = mod( (time),        60.0 );
    float mins = mod( (time/60.0),   60.0 );
    float hors = mod( (time/3600.0), 24.0 );
    
    vec3 d = vec3(1.);
    
    int c = 0;
    for( int count=0; count < kMaxDepth; count++ )
    {
        int off = kMaxDepth;
        vec2 pt_n = pos;
        
        float l = len;
        float w = wid;
        
          for( int i=1; i<=kDepth; i++ )
          {
            l *= lenf;
            w *= widf;

            off /= kBranches; 
            int dec = c / off;
            int path = dec - kBranches*(dec/kBranches); //  dec % kBranches
            
            mat3 mx;
            if( path == 0 )
               {
                  mx = matRotate(6.2831*secs/60.0) * matTranslate( 0.0,l/lenf);
            }
            else if( path == 1 )
               {
                  mx = matRotate(6.2831*hors/60.0) * matTranslate( 0.0,l/lenf);
            }
            else
            {
                  mx = matRotate(6.2831*mins/60.0) * matTranslate(0.0,l/lenf);
            }
            pt_n = (mx * vec3(pt_n,1)).xy;

            
        
            // bounding sphere test
            float y = length( pt_n - vec2(0.0, l) );
               if( y-1.4*l > 0.0 ) { c += off-1; break; }

            float br = sdBranch( pt_n, w, w*widf, l );
            if( path == 0 ){
                d.r = min( d.r, br );
            } else if( path == 1 ){
                d = min( d, br );
            } else {
                d.g = min( d.g, br );
            }
         }
        
        c++;
        if( c > kMaxDepth ) break;
    }
    
       return d;
}

void main(void)
{
    // coordinate system
    vec2  uv = (-resolution.xy + 2.0*gl_FragCoord.xy) / resolution.y;
    float px = 2.0/resolution.y;

    // frame in screen
    vec2  uv_clock = uv*4.0 + vec2(0.0,3.5);
   
    
    // compute
    vec3 d = vec3(map( uv_clock ));
    
    // shape
    vec3 cola = 1.-vec3( smoothstep( 0.0, 5.0*px, d ) );
    glFragColor = vec4( cola, 1.0 );
}

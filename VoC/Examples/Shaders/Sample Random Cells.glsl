#version 420

// original https://www.shadertoy.com/view/wt2SDt

uniform float time;
uniform vec4 date;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float JITTER = 1.0;          // jitter Voronoi amount. 1 = stay in cell

float Random1D(float seed)
{
    return fract(sin(seed)*32767.0);
}

float Random2DS(vec2 p, float s)
{
    return fract(sin(dot(p,vec2(127.1,311.7)))*18.5453 * (1.0+s));
}

// Ala Fab. N.
#define disp(p) ( -(JITTER-1.0)/2.0 + JITTER * (p) )

vec2 Voronoi1D( vec2 u, float seed )
{
    vec2  n = floor( u );
    float f = fract( u.x );

    vec2 m = vec2(1e5);
    for( float g=-2.0; g<=2.0; g++ )
        {
            float o = Random2DS(n + vec2(g,0), seed);
            float d = abs(g - f + disp(o));
            if( d < m.x )
                m = vec2( d, o );
        }

    return m;
}

vec4 RandomCell(vec2 uv, float scale, float seed)
{
    uv *= scale;
    
    vec2 vert = Voronoi1D(uv.yy, seed);
    float vdist = vert.x;
    float vid = vert.y;
    
    float hseed = Random1D(vert.y * seed)*100.0;
    
    vec2 horiz = Voronoi1D(vec2(uv.x + hseed, uv.y + hseed), seed);
    float hdist = horiz.x;
    float hid = horiz.y;
        
    vec4 rv = vec4(hid,vid,hdist,vdist);
        
    return rv;
}

vec4 RandomGrid(vec2 uv, float scale, int iterations, float lac, float seed)
{
    float dampen = 1.0 / (2.0 * scale);
    vec4 rv = RandomCell(uv, scale, seed); 
    rv.xy *= dampen;
    scale *= lac;
    
    for(int i=0; i<6 - 1; i++)
    {
        dampen = 1.0 / (2.0 * scale);
        vec4 cell = RandomCell(uv, scale, seed);
        rv = vec4(rv.xy + (cell.xy*dampen), cell.wz);
        
        scale *=lac;
    }
    
   
    return rv;
}

void main(void)
{
    vec2 U = gl_FragCoord.xy;

    vec2 p = U/(resolution.y);
    p.y += time * 0.2;
    float seed = Random1D(floor(time / 3.0)) + date.x + date.y;   
    
    vec4 cc = RandomGrid(p, 1.0, 6, 2.0, seed);
    
    float cellC = cc.z + cc.w;
    vec3 col;
    
    // col = vec3(cc.x, cc.z, cc.w);
    col = cc.xxy;
        
    glFragColor = vec4(col,1.0);
}

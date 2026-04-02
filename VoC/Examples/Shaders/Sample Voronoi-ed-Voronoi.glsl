#version 420

// original https://www.shadertoy.com/view/NtdXRn

uniform float time;
uniform vec4 date;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// wat?

vec2 hash2( vec2 p )
{
    // procedural white noise    
    return fract(sin(vec2(dot(p,vec2(127.1,311.7)),dot(p,vec2(269.5,183.3))))*43758.5453);
}

vec3 GetWater(vec2 p)
{
    const vec3 col = vec3(0.02,.3,.55);
    const mat3 _m = mat3(-2.0,-1.0,2.0, 3.0,-2.0,1.0, 1.0,2.0,2.0);
    vec4 d = vec4(date*.122);
    d.xy = p;
    d.xyw *=_m*.5;
    float v1 = length(.5-fract(d.xyw));
    d.xyw *=_m*.4;
    float v2 = length(.5-fract(d.xyw));
    d.xyw *=_m*.3;
    float v3 = length(.5-fract(d.xyw));
    float v = pow(min(min(v1,v2),v3), 5.)*15.;
    return col+vec3(v,v,v);
}

// Voronoi (IQ) - slightly modified to return get the ID etc.
vec4 VoronoiGrid( in vec2 x, out vec2 id )
{
    vec2 n = floor(x);
    vec2 f = fract(x);

    // first pass: regular voronoi
    vec2 mg, mr;

    float md = 8.0;
    for( int j=-1; j<=1; j++ )
    for( int i=-1; i<=1; i++ )
    {
        vec2 g = vec2(float(i),float(j));
        vec2 o = hash2( n + g );
        vec2 r = g + o - f;
        float d = dot(r,r);
        if( d<md )
        {
            md = d;
            mr = r;
            mg = g;
        }
    }
    
    // second pass: distance to borders
    md = 8.0;
    for( int j=-2; j<=2; j++ )
    for( int i=-2; i<=2; i++ )
    {
        vec2 g = mg + vec2(float(i),float(j));
        vec2 o = hash2( n + g );
        vec2 r = g + o - f;

        if( dot(mr-r,mr-r)>0.00001 )
        md = min( md, dot( 0.5*(mr+r), normalize(r-mr) ) );
    }
    
    id = (n+mg)+vec2(0.5); // ID is n+mg
    return vec4(md, length(mr), mr);
}
mat2 rotate(float a)
{
    float c = cos(a);
    float s = sin(a);
    return mat2(c, s, -s, c);
}    

void main(void)
{
       vec2 uv = (gl_FragCoord.xy - 0.5 * resolution.xy) / resolution.y;
    uv *= rotate(fract(time*0.025)*6.28);
    vec2 id;
    float scale = 24.0+(5.0*sin(time));
    vec4 grid = VoronoiGrid(uv*scale,id);
    uv = id/scale;
    
    uv.xy += time*0.01;

    float dd = smoothstep(0.0,0.25,(grid.x));

    glFragColor = vec4( GetWater(uv)*dd, 1.0 );
}

#version 420

// original https://www.shadertoy.com/view/tsdcWs

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 voronoi_noise_randomVector(vec2 UV, vec2 offset)
{
    mat2 m =     mat2(15.27, 47.63, 99.41, 89.98);
    UV = fract(sin(UV* m) * 46839.32);
    return vec2(sin(UV.y * +offset.x) * 0.5 + 0.5, cos(UV.x * offset.y) * 0.5 + 0.5);
}

void Voronoi(vec2 UV, vec2 AngleOffset, vec2 CellDensity, out float Out, out float Cells, out float Lines,out float Points)
{
    vec2 g = floor(UV * CellDensity);
    vec2 f = fract(UV * CellDensity);
    
    float res = 8.0;
    float md=8.0;
    vec2 mr;
    for (int y = -1; y <= 1; y++)
     {
        for (int x = -1; x <= 1; x++)
        {
            vec2 lattice = vec2(x, y);
            vec2 offset = voronoi_noise_randomVector(lattice + g, AngleOffset);
            vec2 r = lattice +offset -f;
            float d = dot(r,r);

            if (d < res)
            {
                res = d;
                mr=r;
            }
        }
    }
    res = 8.0;
    for (int y = -1; y <= 1; y++)
     {
        for (int x = -1; x <= 1; x++)
        {
            vec2 lattice = vec2(x, y);
            vec2 offset = voronoi_noise_randomVector(lattice + g, AngleOffset);
            vec2 r = lattice +offset -f;
            float d = dot(r,r);

            if (d < res)
            {
                res = d;
                Out = res;
                Cells = offset.x;
            }
            if( dot(mr-r,mr-r)>0.00001)
            {
                md = min( md, dot( 0.5*(mr+r), normalize(r-mr) ) );
            }
        }
    }
    Lines = mix(1.0, 0.0, smoothstep( 0.0, 0.1, md ));
    Points =1.0-smoothstep( 0.0, 0.1, res );
}
float noise_randomValue(vec2 uv)
{
    return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453);
}
float noise_interpolate(float a, float b, float t)
{
    return (1.0 - t) * a + (t * b);
}
float valueNoise(vec2 uv)
{
    vec2 i = floor(uv);
    vec2 f = fract(uv);
    f = f * f * (3.0 - 2.0 * f);
    uv = abs(fract(uv) - 0.5);
    vec2 c0 = i + vec2(0.0, 0.0);
    vec2 c1 = i + vec2(1.0, 0.0);
    vec2 c2 = i + vec2(0.0, 1.0);
    vec2 c3 = i + vec2(1.0, 1.0);
    float r0 = noise_randomValue(c0);
    float r1 = noise_randomValue(c1);
    float r2 = noise_randomValue(c2);
    float r3 = noise_randomValue(c3);
    float bottomOfGrid = noise_interpolate(r0, r1, f.x);
    float topOfGrid = noise_interpolate(r2, r3, f.x);
    float t = noise_interpolate(bottomOfGrid, topOfGrid, f.y);
    return t;
}
void SimpleNoise(vec2 UV, float Scale, out float Out)
{
    float t = 0.0;
    float freq = pow(2.0, float(0));
    float amp = pow(0.5, float(3 - 0));
    t += valueNoise(vec2(UV.x * Scale / freq, UV.y * Scale / freq)) * amp;
    freq = pow(2.0, float(1.0));
    amp = pow(0.5, float(2.0));
    t += valueNoise(vec2(UV.x * Scale / freq, UV.y * Scale / freq)) * amp;
    freq = pow(2.0, float(2.0));
    amp = pow(0.5, float(1.0));
    t += valueNoise(vec2(UV.x * Scale / freq, UV.y * Scale / freq)) * amp;
    Out = t;
}
void Spherize(vec2 UV, vec2 Center, float Strength, vec2 Offset, out vec2 Out)
{
    vec2 delta = UV - Center;
    float delta2 = dot(delta.xy, delta.xy);
    float delta4 = delta2 * delta2;
    vec2 delta_offset = vec2(delta4 * Strength);
    Out = UV + delta * delta_offset + Offset;
}

void main(void)
{
    vec2 uv =  ( 2.*gl_FragCoord.xy - resolution.xy ) / resolution.y;
    vec3 col;
    vec2 uv2=uv;
    Spherize(uv, vec2(0.0,0.0),0.2,vec2(7.0),uv);
    
    float a,b,c,d; 
    Voronoi(uv2,vec2(3.0),vec2(7.0),a,b,c,d);
    
    float aa,bb,cc,dd; 
    vec2 sc=uv+vec2(0.0,time/10.0);
    Voronoi(sc,vec2(7.0),vec2(11.0),aa,bb,cc,dd);
    
    float e;
    SimpleNoise(uv,200.0,e);
    
    col.r=aa+a;
    col.g=aa/2.0+a/2.0*e;
    glFragColor = vec4(col,1.0);
}

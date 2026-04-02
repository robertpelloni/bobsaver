#version 420

// original https://www.shadertoy.com/view/lllGRr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//Triangulator by nimitz (twitter: @stormoid)

#define ITR 40
#define FAR 100.
#define time2 time*0.2

mat2 mm2(in float a){float c = cos(a), s = sin(a);return mat2(c,-s,s,c);}
mat2 m2 = mat2(0.934, 0.358, -0.358, 0.934);
float tri(in float x){return abs(fract(x)-0.5);}

float heightmap(in vec2 p)
{
    p*=.05;
    float z=2.;
    float rz = 0.;
    for (float i= 1.;i < 4.;i++ )
    {
        rz+= tri(p.x+tri(p.y*1.5))/z;
        z = z*-.85;
        p = p*1.32;
        p*= m2;
    }
    rz += sin(p.y+sin(p.x*.9))*.7+.3;
    return rz*5.;
}

//from jessifin (https://www.shadertoy.com/view/lslXDf)
vec3 bary(vec2 a, vec2 b, vec2 c, vec2 p) 
{
    vec2 v0 = b - a, v1 = c - a, v2 = p - a;
    float inv_denom = 1.0 / (v0.x * v1.y - v1.x * v0.y)+1e-9;
    float v = (v2.x * v1.y - v1.x * v2.y) * inv_denom;
    float w = (v0.x * v2.y - v2.x * v0.y) * inv_denom;
    float u = 1.0 - v - w;
    return abs(vec3(u,v,w));
}

/*
    Idea is quite simple, find which side if a given tile we're in,
    then get 3 samples and compute height using barycentric coordinates.
*/
float map(vec3 p)
{
    vec3 q = fract(p)-0.5;
    vec3 iq = floor(p);
    vec2 p1 = vec2(iq.x-.5, iq.z+.5);
    vec2 p2 = vec2(iq.x+.5, iq.z-.5);
    
    float d1 = heightmap(p1);
    float d2 = heightmap(p2);
    
    float sw = sign(q.x+q.z); 
    vec2 px = vec2(iq.x+.5*sw, iq.z+.5*sw);
    float dx = heightmap(px);
    vec3 bar = bary(vec2(.5*sw,.5*sw),vec2(-.5,.5),vec2(.5,-.5), q.xz);
    return (bar.x*dx + bar.y*d1 + bar.z*d2 + p.y + 3.)*.9;
}

float march(in vec3 ro, in vec3 rd)
{
    float precis = 0.001;
    float h=precis*2.0;
    float d = 0.;
    for( int i=0; i<ITR; i++ )
    {
        if( abs(h)<precis || d>FAR ) break;
        d += h;
        float res = map(ro+rd*d)*1.1;
        h = res;
    }
    return d;
}

vec3 normal(const in vec3 p)
{  
    vec2 e = vec2(-1., 1.)*0.015;
    return normalize(e.yxx*map(p + e.yxx) + e.xxy*map(p + e.xxy) + 
                     e.xyx*map(p + e.xyx) + e.yyy*map(p + e.yyy) );   
}

void main(void)
{    
    vec2 p = gl_FragCoord.xy/resolution.xy-0.5;
    p.x*=resolution.x/resolution.y;
    vec2 um = vec2(0.45+sin(time2*0.7)*2., -.18);
    
    vec3 ro = vec3(sin(time2*0.7+1.)*20.,3., time2*50.);
    vec3 eye = normalize(vec3(cos(um.x), um.y*5., sin(um.x)));
    vec3 right = normalize(vec3(cos(um.x+1.5708), 0., sin(um.x+1.5708)));
    right.xy *= mm2(sin(time2*0.7)*0.3);
    vec3 up = normalize(cross(right, eye));
    vec3 rd=normalize((p.x*right+p.y*up)*1.+eye);
    
    float rz = march(ro,rd);
    vec3 col = vec3(0.);
    
    if ( rz < FAR )
    {
        vec3 pos = ro+rz*rd;
        vec3 nor= normal(pos);
        vec3 ligt = normalize(vec3(-.2, 0.05, -0.2));
        
        float dif = clamp(dot( nor, ligt ), 0., 1.);
        float fre = pow(clamp(1.0+dot(nor,rd),0.0,1.0), 3.);
        vec3 brdf = 2.*vec3(0.10,0.11,0.1);
        brdf += 1.9*dif*vec3(.8,1.,.05);
        col = vec3(0.35,0.07,0.5);
        col = col*brdf + fre*0.5*vec3(.7,.8,1.);
    }
    col = clamp(col,0.,1.);
    col = pow(col,vec3(.9));
    glFragColor = vec4( col, 1.0 );
}

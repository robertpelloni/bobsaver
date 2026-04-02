#version 420

// original https://www.shadertoy.com/view/3dy3Rt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Code by Flopine
// Thanks to wsmind, leon, XT95, lsdlive, lamogui, Coyhot, Alkama and YX for teaching me
// Thanks LJ for giving me the love of shadercoding :3

// Thanks to the Cookie Collective, which build a cozy and safe environment for me 
// and others to sprout :)  https://twitter.com/CookieDemoparty

#define PI 3.141592

vec2 rand (vec2 x)
{return fract(sin(vec2(dot(x, vec2(1.2,5.5)), dot(x, vec2(4.54,2.41))))*4.45);}

float hash11 (float x)
{return fract(sin(x*45.15)*124.5);}

float hash21 (vec2 x)
{return fract(sin(dot(x,vec2(12.45,43.158)))*1245.5);}

mat2 rot(float a)
{return mat2(cos(a),sin(a),-sin(a),cos(a));}

float moda (inout vec2 p, float rep)
{
    float per = 2.*PI/rep;
    float a= atan(p.y,p.x);
    float l = length(p);
    float id = floor(a/per);
    a = mod(a, per)-per*0.5;
    p = vec2(cos(a),sin(a))*l;
    if (abs(id) >= (rep/2.)) id = abs(id);
    return id;
}

float stmin(float a, float b, float k, float n)
{
    float st = k/n;
    float u = b-k;
    return min(min(a,b),0.5*(u+a+abs(mod(u-a+st,2.*st)-st)));
}

// voronoi function which is a mix between Book of Shaders : https://thebookofshaders.com/12/?lan=en
// and iq article : http://www.iquilezles.org/www/articles/voronoilines/voronoilines.htm
vec3 voro (vec2 uv)
{
    vec2 uv_id = floor (uv);
    vec2 uv_st = fract(uv);

    vec2 m_diff;
    vec2 m_point;
    vec2 m_neighbor;
    float m_dist = 10.;

    for (int j = -1; j<=1; j++)
    {
        for (int i = -1; i<=1; i++)
        {
            vec2 neighbor = vec2(float(i), float(j));
            vec2 point = rand(uv_id + neighbor);
            point = 0.5+0.5*sin(2.*PI*point+time);
            vec2 diff = neighbor + point - uv_st;

            float dist = length(diff);
            if (dist < m_dist)
            {
                m_dist = dist;
                m_point = point;
                m_diff = diff;
                m_neighbor = neighbor;
            }
        }
    }

    m_dist = 10.;
    for (int j = -2; j<=2; j++)
    {
        for (int i = -2; i<=2; i++)
        {
            if (i==0 && j==0) continue;
            vec2 neighbor = m_neighbor + vec2(float(i), float(j));
            vec2 point = rand(uv_id + neighbor);
            point = 0.5+0.5*sin(point*2.*PI+time);
            vec2 diff = neighbor + point - uv_st;
            float dist = dot(0.5*(m_diff+diff), normalize(diff-m_diff));
            m_point = point;
            m_dist = min(m_dist, dist);
        }
    }

    return vec3(m_point, m_dist);
}

float box (vec3 p, vec3 c)
{
    vec3 q = abs(p)-c;
    return min(0., max(q.x,max(q.y,q.z))) + length(max(q,0.));
}

float cyl (vec3 p, float r, float h)
{return max(length(p.xy)-r, abs(p.z)-h);}

float od (vec3 p, float r)
{return dot(p,normalize(sign(p)))-r;}

float g1 = 0.;
float room (vec3 p)
{
    p.y -= 5.;
    p.y -= step(0.05,voro(p.xz).z)*0.05;
    p.y += sin(length(p.xz*1.5)-time)*0.1;
    
    p.x -= step(0.05,voro(p.yz).z)*0.05;
    p.x += sin(length(p.yz*1.5)-time)*0.1;
    
    float d = -box(p, vec3(10.,8.,15.));
    g1 += 0.1/(0.1+d*d);
    return d;
}

float t_id;
float g2 = 0.;
float tentacles (vec3 p)
{
    p.xz *= rot(sin(time+p.y*0.8)*0.5);
    t_id = moda(p.xz, 7.);

    p.x -= 2.;
    float d = cyl(p.xzy, 0.15 - p.y*0.1,3.);
    g2 += 0.1/(0.1+d*d);
    return d;
}

float gem (vec3 p)
{
    p.y -= 1.5;
    p.xz *= rot(time);
    p.xy *= rot(time);
    p.y += sin(time)*0.5+0.5;
    return stmin(od(p, 1.),box(p,vec3(0.9)),0.5,3.);
}

float SDF (vec3 p)
{
    return min(gem(p),min(room(p),tentacles(p)));
}

vec3 getcam (vec3 ro, vec3 tar, vec2 uv)
{
    vec3 f = normalize(tar-ro);
    vec3 l = normalize(cross(vec3(0.,1.,0.),f));
    vec3 u = normalize(cross(f,l));
    return normalize(f + l*uv.x + u*uv.y);
}

void main(void)
{

    vec2 uv = 2.*(gl_FragCoord.xy/resolution.xy)-1.;
    uv.x *= resolution.x/resolution.y;
    
    float dither = hash21(uv);
    
    vec3 ro = vec3(0.001,2.,-5.5),
        tar = vec3(0.,0.,0.),
        rd = getcam(ro, tar, uv),
        p = ro,
        col = vec3(0.);
    
    float shad = 0.;
    
    for (float i=0.; i<64.;i++)
    {
        float d = SDF(p);
        if (d<0.001)
        {
            shad = i/64.;
            break;
        }
        d *= 0.9+dither*0.1;
        p += d*rd;
    }

    float t = length(ro-p);
    
    col = vec3(shad);
    col += g1 * step(voro(p.xz+p.yz).z,0.05) * vec3(0.,0.3,0.4);
    col += g2 * vec3(hash11(t_id)*0.1,1.,hash11(t_id))*0.2;
    
    col = mix(col, vec3(0.2,0.2,0.3), 1.-exp(-0.018*t*t));

    glFragColor = vec4(col,1.0);
}

#version 420

// original https://www.shadertoy.com/view/llscW7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//source: https://www.shadertoy.com/view/4sjXW1 https://www.shadertoy.com/view/ld2fRt

//Przemyslaw Zaworski, 11.09.2017, version 1.0

#define time time

float generate_map = 50.0;

mat2 mm2(in float a){float c = cos(a), s = sin(a);return mat2(c,-s,s,c);}

float noise (vec3 n) 
{ 
    return fract(sin(dot(n, vec3(95.43583, 93.323197, 94.993431))) * 65536.32);
}

float perlin_a (vec3 n)
{
    vec3 base = floor(n * 64.0) * 0.015625;
    vec3 dd = vec3(0.015625, 0.0, 0.0);
    float a = noise(base);
    float b = noise(base + dd.xyy);
    float c = noise(base + dd.yxy);
    float d = noise(base + dd.xxy);
    vec3 p = (n - base) * 64.0;
    float t = mix(a, b, p.x);
    float tt = mix(c, d, p.x);
    return mix(t, tt, p.y);
}

float perlin_b (vec3 n)
{
    vec3 base = vec3(n.x, n.y, floor(n.z * 64.0) * 0.015625);
    vec3 dd = vec3(0.015625, 0.0, 0.0);
    vec3 p = (n - base) *  64.0;
    float front = perlin_a(base + dd.yyy);
    float back = perlin_a(base + dd.yyx);
    return mix(front, back, p.z);
}

float fbm(vec3 n)
{
    float total = 0.0;
    float m1 = 1.0;
    float m2 = 0.1;
    for (int i = 0; i < 5; i++)
    {
        total += perlin_b(n * m1) * m2;
        m2 *= 2.0;
        m1 *= 0.5;
    }
    return total;
}

vec3 heightmap (vec3 n)
{
    return vec3(fbm((5.0 * n) + fbm((5.0 * n) * 3.0 - 1000.0) * 0.05),0,0);
}

vec3 hsv2rgb( in vec3 c )
{
    vec3 rgb = clamp( abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),6.0)-3.0)-1.0, 0.0, 1.0 );
    return c.z * mix( vec3(1.0), rgb, c.y);
}

vec3 tex(in vec2 p)
{
    float frq =20.3;
    p += 0.105;
    return vec3(1.0)*smoothstep(.99, 1., max(sin((p.x)*frq),sin((p.y)*frq)));
}

float iSphere(in vec3 ro, in vec3 rd)
{
    vec3 oc = ro;
    float b = dot(oc, rd);
    float c = dot(oc,oc) - 1.;
    float h = b*b - c;
    if(h <0.0) return -1.;
    return -b - sqrt(h);
}

vec4 atlas(vec2 uv)
{    
    vec4 f = vec4(0.0);
     float color = clamp(vec4(vec3((heightmap(vec3(uv.xy*5.0,generate_map)*0.02)-1.0)),1.0).r,0.0,1.0);
    if (color<0.1) f=vec4(0.77,0.90,0.98,1.0);
    else
    if (color<0.2) f=vec4(0.82,0.92,0.99,1.0);
    else
    if (color<0.3) f=vec4(0.91,0.97,0.99,1.0);
    else
    if (color<0.55) f=vec4(0.62,0.75,0.59,1.0);
    else
    if (color<0.65) f=vec4(0.86,0.90,0.68,1.0);
    else
    if (color<0.75) f=vec4(0.99,0.99,0.63,1.0);
    else
    if (color<0.85) f=vec4(0.99,0.83,0.59,1.0);
    else
    if (color<0.95) f=vec4(0.98,0.71,0.49,1.0);     
    else
    if (color<0.99) f=vec4(0.98,0.57,0.47,1.0);        
    else      
    f=vec4(0.79,0.48,0.43,1.0); 
    return f;
}

void main(void)
{    
    vec2 p = gl_FragCoord.xy/resolution.xy-0.5;
    p.x*=resolution.x/resolution.y;
    vec2 um = mouse*resolution.xy.xy / resolution.xy-.5;
    um.x *= resolution.x/resolution.y;
    p*= 1.5;
    vec3 ro = vec3(0.,0.,2.4);
    vec3 rd = normalize(vec3(p,-1.5));
    mat2 mx = mm2(time*.4+um.x*5.);
    mat2 my = mm2(time*0.4+um.y*5.); 
    ro.xz *= mx;rd.xz *= mx;  
    float t = iSphere(ro,rd);
    vec3 col = 1.7-vec3(length(p));
    if (t > 0.)
    {
        vec3 pos = ro+rd*t;
        p=vec2(acos(pos.y/length(pos)), atan(pos.z,pos.x));
        vec2 sph = vec2(acos(pos.y/length(pos)), atan(pos.z,pos.x));
        vec3 colo = tex(sph*3.0);
        colo.x = sph.x*0.5;
        vec3 lines = hsv2rgb(vec3(colo.x,0.5,colo.z));    
        col = (atlas(p).xyz+lines);        
    }  
    glFragColor = vec4(col, 1.0);
}

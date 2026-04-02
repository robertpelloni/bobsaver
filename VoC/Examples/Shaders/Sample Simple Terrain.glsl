#version 420

// original https://www.shadertoy.com/view/Md3GRn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*The moment aliasing actually make things better ahahahaha*/
const float dMax = 100.0;
const float dSea = 30.3;
const int ITER_FRAGMENT = 4;
const float SEA_HEIGHT = 1.1;
const float SEA_CHOPPY = 0.9;
const float SEA_SPEED = 1.0;
const float SEA_FREQ = 0.3;
const vec3 SEA_BASE = vec3(0.1,0.29,0.19);
const vec3 SEA_WATER_COLOR = vec3(0.8,1.0,0.8);
float SEA_time = 0.;
vec3 camEye;
mat2 octave_m = mat2(1.6,1.2,-1.2,1.6);

const mat2 rotate2D = mat2(1.732, 1.323, -1.523, 1.652);
vec3 sunColour = vec3(1.0, .75, .4);
vec3 sunP;
vec3 sunLight;
float Hash( float n );
vec3 noise( in vec2 x );
float snoise(vec2 p);
float Terrain(vec2 p);
vec3 GetSky(in vec3 rd);
vec3 doLight(vec3 ro, vec3 rd, vec2 res);
vec3 getNormal(vec3 p);

float sea_octave(vec2 uv, float choppy) 
{
        uv += snoise(uv);        
        vec2 wv = 1.0-abs(cos(uv));
        return pow(1.0-pow(wv.x * wv.y,0.65),choppy);
}

float Sea(vec3 p)
{
    float freq = SEA_FREQ;
        float amp = SEA_HEIGHT;
        float choppy = SEA_CHOPPY;
        vec2 uv = p.xz; uv.x *= 0.75;
    
        float d, h = 0.0;    
        for(int i = 0; i < ITER_FRAGMENT; i++) 
    {        
            d = sea_octave((uv + SEA_time)*freq,choppy);
            d += sea_octave((uv - SEA_time)*freq,choppy);
               
        h += d * amp;        
            uv *= octave_m; freq *= 1.9; amp *= 0.22;
            choppy = mix(choppy,1.0,.2);
    }
    return p.y - h;    
}

float specular(vec3 n,vec3 l,vec3 e,float s) 
{    
    float nrm = (s + 8.0) / (3.1415 * 8.0);
    return pow(max(dot(reflect(e,n),l),0.0),s) * nrm;
}

vec3 getSeaColor(vec3 p, vec3 n, vec3 l, vec3 eye, vec3 dist) 
{  
        float fresnel = 1.0 - max(dot(n,-eye),0.0);
        fresnel = pow(fresnel,3.0) * 0.85;
        
        vec3 reflected = GetSky(reflect(eye,n));    
        vec3 refracted = SEA_BASE; 
    
        vec3 color = mix(refracted,reflected,fresnel);
    
        float atten = max(1.0 - dot(dist,dist) * 0.001, 0.2);
        color += SEA_WATER_COLOR * (p.y - SEA_HEIGHT) * 0.18 * atten;
   
        color += vec3(specular(n,l,eye,10.0));
        return color;
}

vec2 map(vec3 p)
{
    float d = Terrain(p.xz);
    float dd = Sea(p);
    float m = -1.0;
    float dist = length(p - camEye);
    d = p.y - d;
    if(d < dSea && dist < dSea + 2.555)
        m = 1.0;
    
    else if(d < dMax)
    {
        d = dd;
         m = 2.0;
    }
    return vec2(d, m); 
}

vec2 raymarch(vec3 ro, vec3 rd)
{
    float t = 0.0;
    float eps = 0.01;
    float h = 2.0*eps;
    float m = -1.0;
    for(int i = 0; i < 20;  i++)
    {
        if(abs(h) > eps || t < dMax)
        {
            t += h;
            vec2 res = map(ro + t*rd);
            h = res.x;
            m = res.y;
        }
        else break;
    }
    if(t > dMax) m = -1.0;
    return vec2(t,m);
}

vec3 render(vec3 ro, vec3 rd)
{
    vec3 color = vec3(0.0);
    vec2 res = raymarch(ro, rd);
    vec3 sky = GetSky(rd);
    color = sky;
    vec3 pos = ro + res.x*rd;
    vec3 nor = getNormal(pos);
    if(res.y > 0.5 && res.y < 1.5)
    {
        color = doLight(ro, rd, res);
        vec3 darker = vec3(0.1);    
        color -= darker;
        vec2 uv = gl_FragCoord.xy/resolution.xy;
        color = mix(color, sky, 0.92*uv.y);
    }
    else if(res.y > 1.5)
    {
        color = mix(
            sky,
               getSeaColor(pos,nor,sunLight,rd,pos - camEye),
            pow(smoothstep(0.0,-.3,rd.y),0.2)) * vec3(0.45);
        float fogAmount = clamp(res.x*res.x* 0.00009, 0.0, 1.0);
        color = mix(color, sky, fogAmount);
    }
    return color;
}

vec3 lensFlare(vec3 rgb, vec3 ww, vec3 uu, vec3 vv,
                                   vec2 uv, vec3 dir)
{
    vec3 color = rgb;
    float bri = dot(ww,sunLight)*.75;
    mat3 camMat = mat3(uu, vv, ww);
    float PI = 3.1415;
    if(bri > 0.0)
    {
        vec2 sunPos = (-camMat * sunLight).xy;
        
        bri = pow(bri, 7.0)*.8;
        float glare = max(dot(normalize(vec3(dir.x, dir.y+.3, dir.z)),sunLight),0.0)*1.4;
        float glare2 = max(sin(smoothstep(.4, .7, length(sunPos - uv*.5))*PI), 0.0);

        float glare3 = max(1.0-length(sunPos - uv*2.1), 0.0);
        float glare4 = max(sin(smoothstep(-0.05, .4, length(sunPos + uv*2.5))*PI), 0.0);

        color += bri * vec3(1.0, .0, .0)  * pow(glare, 12.5)*.07;
        color += bri * vec3(.0, 1.0, 1.0) * pow(glare2, 3.0);
        color += bri * vec3(1.0, 1.0, 0.0)* pow(glare3, 3.0)*4.0;
        color += bri * vec3(.5, 1.0, 1.0) * pow(glare4, 33.9)*.7;
    }     
    return color;
}

vec3 PostProcess(vec3 rgb, vec2 xy)
{
    rgb = pow(rgb, vec3(0.45));
    float contrast = 1.3;
    float saturation = 1.0;
    float brightness = 1.3;
    rgb = mix(vec3(0.5), mix(vec3(dot(vec3(.2125, .7154, .0721), 
                    rgb*brightness)), rgb*brightness, saturation), contrast); 
    rgb *= 0.4 + 0.4*pow(40.0*xy.x*xy.y*(1.0-xy.x)*(1.0-xy.y), 0.2);
    return rgb;
}

void main(void)
{
    sunP = vec3(1000.0, 750.0 + 650.0*sin(0.5*time), 3500.0);
       sunLight = normalize(sunP);
    SEA_time = time * SEA_SPEED;
    vec2 xy = gl_FragCoord.xy/resolution.xy;
    vec2 uv = 2.0*xy - 1.0;
    uv.x *= resolution.x/resolution.y;
    float x = 0.0 ;
    float y = 10.0;
    float z = -11.0;
    vec3 eye = vec3(x,y,z);
    vec3 at = vec3(eye.x +4.0, eye.y - 0.9, 0.0);
    camEye = eye;
    //at.x *= 5.0*sin(time);
    vec3 up = vec3(0.0, 1.0, 0.0);
    vec3 ww = normalize(at-eye);
    vec3 uu = normalize(cross(ww, up));
    vec3 vv = normalize(cross(uu, ww));
    vec3 rd = normalize(uv.x*uu + uv.y*vv + 2.0*ww);
    vec3 ro = eye;
    vec3 color = render(ro, rd);
    color = lensFlare(color, ww, uu, vv, uv, rd);
    color = PostProcess(color, xy);
    glFragColor = vec4(color, 1.0);
}

vec3 getNormal(vec3 p)
{
    vec3 n;
    float eps = 0.001;
    n.x = map(vec3(p.x + eps, p.y, p.z)).x - map(vec3(p.x - eps, p.y, p.z)).x; 
    n.y = map(vec3(p.x, p.y + eps, p.z)).x - map(vec3(p.x, p.y - eps, p.z)).x;
    n.z = map(vec3(p.x, p.y, p.z + eps)).x - map(vec3(p.x, p.y, p.z - eps)).x;
    return normalize(n);
}

vec3 doLight(vec3 ro, vec3 rd, vec2 res)
{
    vec3 pos = ro + res.x*rd;
    vec3 nor = getNormal(pos);
    vec3 lightv = sunP - pos;    
    float dist = length(lightv);
    lightv = normalize(lightv);
    float at = 1500.0/(.0 + 0.1*dist);
    vec3 difc = vec3(0.7, 0.5, 0.2);
    vec3 dif = at*sunColour*max(0., dot(lightv, nor))*difc;
    vec3 refl = reflect(lightv, nor);
    float s = dot(lightv, refl);
    vec3 spec = vec3(0.0);
    if(s > 0.7)
        dif -= vec3(0.1)*pow(s, 64.0);
    return max(dif + spec, 0.1);
}

float Terrain(vec2 p)
{
    vec2 pos = p*0.0035;
    float w = 24.0;
    float f = 0.0;
    vec2 d = vec2(0.0);
    for(int i = 0; i < 8; i++)
    {
        vec3 n = noise(pos);
        d += n.yz;
        f += w*n.x/(1.0 + dot(d,d));
        w = w*0.57;
        pos = rotate2D * pos;
    }
    return f;
}

float snoise(vec2 p) 
{
    vec2 f = fract(p);
    p = floor(p);
    float v = p.x+p.y*1000.0;
    vec4 r = vec4(v, v+1.0, v+1000.0, v+1001.0);
    r = fract(100000.0*sin(r*.001));
    f = f*f*(3.0-2.0*f);
    return 2.0*(mix(mix(r.x, r.y, f.x), mix(r.z, r.w, f.x), f.y))-1.0;
}

vec3 GetSky(in vec3 rd)
{
    float sunAmount = max( dot( rd, sunLight), 0.0 );
    float v = pow(1.0-max(rd.y,.0),3.);
    vec3  sky = mix(vec3(.015,0.0,.01), vec3(.42, .2, .1), v);
    sky = sky + sunColour * sunAmount * sunAmount * .5;
    sky = sky + sunColour * min(pow(sunAmount, 800.0)*1.5, .4);
    return clamp(sky, 0.3, 1.0);
}

vec3 noise( in vec2 x )
{
    vec2 p = floor(x);
    vec2 f = fract(x);
    vec2 u = f*f*(3.0-2.0*f);
    float n = p.x + p.y*57.0;

    float a = Hash(n+  0.0);
    float b = Hash(n+  1.0);
    float c = Hash(n+ 57.0);
    float d = Hash(n+ 58.0);
    return vec3(a+(b-a)*u.x+(c-a)*u.y+(a-b-c+d)*u.x*u.y,
                30.0*f*f*(f*(f-2.0)+1.0)*(vec2(b-a,c-a)+(a-b-c+d)*u.yx));
}

float Hash( float n )
{
    return fract(sin(n)*33753.545383);
}

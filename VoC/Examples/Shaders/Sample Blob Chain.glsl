#version 420

// original https://www.shadertoy.com/view/ssySDy

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const vec3 g_lightDir = normalize(vec3(-1.0, 0.6, -1.0));
const vec3 g_bakLightDir = normalize(vec3(1.0, -0.7, 1.5));

const float g_tg = 0.98; // point light trigger

// ------------------------------------------------

#define ZERO (min(frames,0))
#define saturate(_a) clamp(_a, 0.0,1.0)

float hash13(ivec3 p)
{
    vec3 p3  = fract(vec3(p) * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

// from IQ
vec3 hash33( uvec3 x )
{
    const uint k = 1103515245U;

    x = ((x>>8U)^x.yzx)*k;
    x = ((x>>8U)^x.yzx)*k;
    x = ((x>>8U)^x.yzx)*k;
    
    return vec3(x)*(1.0/float(0xffffffffU));
}

vec3 hash33( ivec3 x )
{
    return hash33( uvec3(x) );
}

// http://iquilezles.org/www/articles/smin/smin.htm
float smin( float a, float b, float k )
{
    float h = max(k-abs(a-b),0.0);
    return min(a, b) - h*h*0.25/k;
}

// http://iquilezles.org/www/articles/smin/smin.htm
float smax( float a, float b, float k )
{
    float h = max(k-abs(a-b),0.0);
    return max(a, b) + h*h*0.25/k;
}

// https://iquilezles.org/www/articles/distfunctions/distfunctions.htm
float sdSphere( in vec3 p, in vec3 c, in float r )
{
    return length(p-c) - r;
}

// on dirait que ca fait des coupure net..

// smin for 2 components, driven by first one(distance)
vec2 smin( vec2 a, vec2 b, float k )
{
    float h = max(k-abs(a.x-b.x),0.0);
    h = h*h*0.25/k;
    
    
    float g = (b.y-a.y)*h;
    
    
    return a.x<b.x ? vec2(a.x-h, a.y+g) : vec2(b.x-h, b.y-g);    
}

#define RING_RADIUS 1.0
#define RING_AMPLITUDE 1.0

const float distErr = max(0.0, sqrt(pow(RING_RADIUS+RING_AMPLITUDE,2.0)*2.0) - 1.5);

vec2 map( in bool highOnly, in vec3 p )
{

    vec2 res = vec2(1000000.0, 1.0);

    float s = 1.0;
    p *= s;
    

    // animate smin
    float sm = 0.01 + 0.99*max(0.0,sin(time*0.2));

    // scan 3 rings of ball (left, center, right)
    for(int i=-1; i<=1; i++)
    {                                
        vec3 f = fract(p);
        f.y = p.y;
        f.z = p.z;

        vec3 cc = vec3(i,0,0);
        vec3 cw = p-f + cc;
        ivec3 bid = ivec3(cw);
        cc += 0.5;// center

        cc.y += RING_AMPLITUDE * sin( cw.x +  time*1.33);
        cc.z += RING_AMPLITUDE * cos( cw.x +  time*1.23);

        const int nb = 8;
        float a = time*(1.17 + sin(cw.x*7.27) ); // twist !
        for(int j=0; j<nb; j++, a+=2.0*3.14159/float(nb))
        {
            ivec3 id = bid; id.y += j;
            vec3 hs = hash33( id );

            float e = fract(hs.x+hs.z);  // random color scale                    
            if(highOnly && e<g_tg) continue;

            vec3 c=cc;
            c.z += RING_RADIUS * cos(a) * (0.4 + 0.6*hs.y);
            c.y += RING_RADIUS * sin(a) * (0.4 + 0.6*hs.z);

            // Random radius
            float r = 0.1 + 0.3*hs.x*(0.7 + 0.3*sin( (0.1 +hs.z*7.31) *  time));

            // Random offset
            float o = fract(hs.x+hs.y)*(1.0-2.0*r) - (0.5-r);                   
            o *= 0.5 + 0.5*sin( (0.1 + hs.x*5.51)*time)*sin(time*(0.2 + 11.1*hs.y));
            c.x += o;

            // sdf
            float d = length(f-c) - r;

            res = smin(res, vec2(d, e), sm );

            res.y = min(1.0, res.y);                                        
        }

        if(res.x<=0.0) break;
    }
    
    res.x /= s;
    
    return res;
}

vec3 calcNormal(in vec3 pos, in float eps )
{
#if 0    
    vec2 e = vec2(1.0,-1.0)*0.5773*eps;
    return normalize( e.xyy*map( pos + e.xyy,outside, MAP_DETAIL_STD ).x + 
       e.yyx*map( pos + e.yyx).x ) + 
       e.yxy*map( pos + e.yxy).x ) + 
       e.xxx*map( pos + e.xxx).x ) );
#else
    // inspired by tdhooper and klems - a way to prevent the compiler from inlining map() 4 times
    vec3 n = vec3(0.0);
    for( int i=ZERO; i<4; i++ )
    {
        vec3 e = 0.5773*(2.0*vec3((((i+3)>>1)&1),((i>>1)&1),(i&1))-1.0);
        n += e*map(false, pos+0.001*e).x;
    }
    return normalize(n);

#endif    
}

vec2 intersect(in float maxdist, in vec3 ro, in vec3 rd )
{
    vec2 res = vec2(-1.0, 0);

    float t = 0.0;

    for( int i=0; i<100; i++ )
    {
        vec3 p = ro + t*rd;
        vec2 h = map( false, p );
        
        if( h.x<(0.0001*t) ||  t>maxdist ) return vec2(t, h.y);

        // we should have perfect distance:
        // but since we offset in a vertical slice, and only scan left&right neigboor,
        // then we need to detect potentially over evaluated distances
      
        t+= h.x<=distErr ? h.x : max(distErr, h.x-distErr);

    }

    return vec2(maxdist, 0.0); //res;
}

// http://iquilezles.org/www/articles/rmshadows/rmshadows.htm
float calcSoftshadow( in vec3 ro, in vec3 rd )
{
    float res = 1.0;

    float tmax = 120.0;
    
    float t = 0.02;
    for( int i=ZERO; i<50; i++ )
    {
        float h = map(false, ro + rd*t ).x;
          
#if 1
        res = min( res, 4.0*h/t );// soft
#else        
        if(t>0.1 && h<=0.0) return 0.0;// hard
#endif        

        t += clamp( h, 0.05, 0.40 );
        if( res<0.005 || t>tmax ) break;
    }
    return max(.0, res );
}

float specular(vec3 ld, vec3 n, vec3 rd, float s)
{
    return pow( max(0.0, dot(reflect(ld,n), rd )), s);
}

float diffuse(vec3 ld, vec3 n)
{
    return saturate( dot(n , ld) );
}

vec3 background(vec3 p, vec3 n)
{
    return vec3(0.3,0.4,0.5)*0.3 * (0.5 + 0.5*dot(n,g_lightDir)  );
}

vec3 calcPointColor(float id)
{
    id = saturate( (id-g_tg)/(1.0-g_tg) );
    float tm = time * ( 0.7 + 0.3*id);
    
    float tc = pow(sin(0.1*tm),2.0);
    vec3 c1 = mix( 1.5*vec3(1.0,0.5 + tc ,0.0), 1.5*vec3(0.0, tc+0.5,tc*tc), tc );
    
    vec3 c2 = mix( 1.5*vec3(1.0,tc*2.0, 0.0), 1.5*vec3(1.0,0.0, tc), tc );
        
    tc = saturate( sin(tm*0.23)*4.0 );
    
    return mix(c1, c2, tc );       
}

vec3 render(in vec3 ro, in vec3 rd, out float tt )
{
    float maxDist = 50.0;
    vec2 t = intersect(maxDist, ro,rd);
    
    tt = t.x;
    
    vec3 col, colBackground = background(ro,rd);
    
    if(t.x>=maxDist)
        col = colBackground; // background
    else
    {

        vec3 p = ro + rd*t.x;
        vec3 n  = calcNormal(p , 0.0001);

        if(t.y>g_tg)
        { // point light/self illum
            col  = calcPointColor(t.y);

            // small halo..
            float r= 0.5; // max radius of a sphere
            float e = map(true, p+rd*r).x;
            col *= smoothstep(0.8, 0.0, e/r);

        }
        else
        {
            // ambient
            vec3 amb; // = 0.2*textureLod( iChannel3, n.xy, 0.0 ).xyz;
            amb += 0.5*background(ro,n);

            // Ball color
            float ty = t.y / g_tg;            
            vec3 colBall = 0.5*mix(vec3(0.3, 0.1, 0.5), vec3(0.9, 0.3, 0.5), ty);

            // directional lighting
            float atten = 0.5 + 0.5*calcSoftshadow(p, g_lightDir);
            col = colBall * ( amb + atten*diffuse(g_lightDir, n) );
            col+= atten*specular(g_lightDir, n, rd, 16.0);

            // animation: show shadowed only
            {
                float u = saturate( sin(time*0.2 + gl_FragCoord.xy.x*0.001)*4.0 );
                col = mix(vec3(atten), col, u );
            }
    
    
            // back light
            float d = 1.0 - min(1.0, 0.1*length(p-vec3(0)) );
            col += /*atten**/0.6*vec3(0.0, 0.7, 1.0)* diffuse(g_bakLightDir, n) * d;

            // lighting with closest point light, by calculating the distance variation along normal, in the light field !
            {
                const float rl = 3.0; // point light radius
                vec2 pl = map( true, p ); // closest point light
                if(pl.x < rl)
                {
                    float dl = (rl-pl.x) * max(0.0, pl.r-map(true, p+n).x) / rl;
                    // lighting + some 'reflectivity'
                    vec3  cl = calcPointColor(pl.y);
                    col += cl*(colBall + 0.2) * dl * 4.0;
                }
            }
        }
        
        // fog
        col = mix(colBackground, col 
                        , smoothstep(maxDist, -3.0, t.x) );
                        //,min(1.0,exp(-.05*t.x + 1.0)) );
    }

    
    return col;
}

mat3 setCamera( in vec3 ro, in vec3 rt, in float cr )
{
    vec3 cw = normalize(rt-ro);
    vec3 cp = vec3(sin(cr), cos(cr),0.0);
    vec3 cu = normalize( cross(cw,cp) );
    vec3 cv = normalize( cross(cu,cw) );
    
    return mat3( cu, cv, cw );
}

vec3 pathCamera(out vec3 ta)
{
    float cTime = time*0.3;

    // camera
    float an = 0.025*sin(0.5*cTime) - 1.25;
    vec3 ro = vec3(5.7,1.6, 5.7);
    
    ro.x = 0.0+ cos(0.5*cTime)*10.0;  
    ro.z = 0.0+ sin(0.5*cTime)*12.0;

    ro.y += sin(0.351*cTime)*16.0;

    ta = vec3(0.0,0.0 + 0.0*sin(0.1*cTime),0);    

    return ro;
}

vec3 ACESFilm(vec3 x)
{
    // Narkowicz 2015, "ACES Filmic Tone Mapping Curve"
    const float a = 2.51;
    const float b = 0.03;
    const float c = 2.43;
    const float d = 0.59;
    const float e = 0.14;
    return (x * (a * x + b)) / (x * (c * x + d) + e);
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    vec2 p = (2.0*(gl_FragCoord.xy)-resolution.xy)/resolution.y;

    // camera
    vec3 ta, ro=pathCamera(ta);

    // ray
    const float fl = 3.5;
    mat3 ca = setCamera( ro, ta, 0.0 );
    vec3 rd = normalize( ca * vec3(p,fl) );

    vec3 col = vec3(0.0);

    // render
    float t;    col += render(ro, rd, t);

    // vignetting    
    col *= 0.5 + 0.5*pow( 16.0*uv.x*uv.y*(1.0-uv.x)*(1.0-uv.y), 0.1 );

    
    // Output to screen    
    glFragColor = vec4( ACESFilm(col), 1.0);
}

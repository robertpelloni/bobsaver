#version 420

// original https://www.shadertoy.com/view/WdsGR8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// festive (and slow) - delz 16/12/2018
// added a couple of slight optimizations, it now actually runs on the iPhoneX ;)

#define PI 3.1415926

//------------------------------------------------------------------------
// Camera
//------------------------------------------------------------------------
void doCamera( out vec3 camPos, out vec3 camTar, in float time)
{
    vec2 mouse2 = vec2(sin(time*0.25)*0.1, 0.6+((0.5+sin(time) * 0.5)*0.5)*2.8);
    float an = 7.0*mouse2.x;
    camPos = vec3(28.5*sin(an),mouse2.y*8.0,28.5*cos(an));
    camTar = vec3(0.0,0.0,0.0);
}

//------------------------------------------------------------------------
// Modelling 
//------------------------------------------------------------------------

float sdPlane( vec3 p )
{
    return p.y;
}

float smin( float a, float b, float k )
{
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}

vec2 opUnionRound(const in vec2 a, const in vec2 b, const in float r)
{
    vec2 res = vec2(smin(a.x,b.x,r),(a.x<b.x) ? a.y : b.y);
    return res;
}

// http://mercury.sexy/hg_sdf/
// Repeat space along one axis. Use like this to repeat along the x axis:
// <float cell = pMod1(p.x,5);> - using the return value is optional.
float pMod1(inout float p, float size)
{
    float halfsize = size*0.5;
    float c = floor((p + halfsize)/size);
    p = mod(p + halfsize, size) - halfsize;
    return c;
}

float line( vec2 p, vec2 a, vec2 b )
{
    vec2 pa = p-a, ba = b-a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return length( pa - ba*h )-0.3;
}

float sdBox( vec3 p, vec3 b )
{
    vec3 d = abs(p) - b;
    return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}    

// model
float A(vec2 p,float d){d=min(d,line(p,vec2(1,-8),vec2(1,-1.5)));d=min(d,line(p,vec2(1,-1.5),vec2(5,-1.5)));d=min(d,line(p,vec2(5,-1.5),vec2(5,-5)));d=min(d,line(p,vec2(5,-5),vec2(1,-5)));d=min(d,line(p,vec2(1,-5),vec2(5,-5)));d=min(d,line(p,vec2(5,-5),vec2(5,-8)));return d;}
//float B(vec2 p,float d){d=min(d,line(p,vec2(4,5),vec2(4,1.5)));d=min(d,line(p,vec2(4,1.5),vec2(1,1.5)));d=min(d,line(p,vec2(1,1.5),vec2(1,8)));d=min(d,line(p,vec2(1,8),vec2(5,8)));d=min(d,line(p,vec2(5,8),vec2(5,5)));d=min(d,line(p,vec2(5,5),vec2(1,5)));return d;}
float C(vec2 p,float d){d=min(d,line(p,vec2(5,-1.5),vec2(1,-1.5)));d=min(d,line(p,vec2(1,-1.5),vec2(1,-8)));d=min(d,line(p,vec2(1,-8),vec2(5,-8)));return d;}
//float D(vec2 p,float d){d=min(d,line(p,vec2(1,8),vec2(4,8)));d=min(d,line(p,vec2(4,8),vec2(4.5,7.5)));d=min(d,line(p,vec2(4.5,7.5),vec2(5,6.25)));d=min(d,line(p,vec2(5,6.25),vec2(5,3.75)));d=min(d,line(p,vec2(5,3.75),vec2(4.5,2)));d=min(d,line(p,vec2(4.5,2),vec2(4,1.5)));d=min(d,line(p,vec2(4,1.5),vec2(1,1.5)));d=min(d,line(p,vec2(1,1.5),vec2(1,8)));return d;}
float E(vec2 p,float d){d=min(d,line(p,vec2(5,-1.5),vec2(1,-1.5)));d=min(d,line(p,vec2(1,-1.5),vec2(1,-5)));d=min(d,line(p,vec2(1,-5),vec2(3,-5)));d=min(d,line(p,vec2(3,-5),vec2(1,-5)));d=min(d,line(p,vec2(1,-5),vec2(1,-8)));d=min(d,line(p,vec2(1,-8),vec2(5,-8)));return d;}
//float F(vec2 p,float d){d=min(d,line(p,vec2(5,1.5),vec2(1,1.5)));d=min(d,line(p,vec2(1,1.5),vec2(1,5)));d=min(d,line(p,vec2(1,5),vec2(3,5)));d=min(d,line(p,vec2(3,5),vec2(1,5)));d=min(d,line(p,vec2(1,5),vec2(1,8)));return d;}
//float G(vec2 p,float d){d=min(d,line(p,vec2(5,2.5),vec2(5,1.5)));d=min(d,line(p,vec2(5,1.5),vec2(1,1.5)));d=min(d,line(p,vec2(1,1.5),vec2(1,8)));d=min(d,line(p,vec2(1,8),vec2(5,8)));d=min(d,line(p,vec2(5,8),vec2(5,5)));d=min(d,line(p,vec2(5,5),vec2(3.5,5)));return d;}
float H(vec2 p,float d){d=min(d,line(p,vec2(1,-1.5),vec2(1,-8)));d=min(d,line(p,vec2(1,-8),vec2(1,-5)));d=min(d,line(p,vec2(1,-5),vec2(5,-5)));d=min(d,line(p,vec2(5,-5),vec2(5,-1.5)));d=min(d,line(p,vec2(5,-1.5),vec2(5,-8)));return d;}
float I(vec2 p,float d){d=min(d,line(p,vec2(1.5,-1.5),vec2(4.5,-1.5)));d=min(d,line(p,vec2(4.5,-1.5),vec2(3,-1.5)));d=min(d,line(p,vec2(3,-1.5),vec2(3,-8)));d=min(d,line(p,vec2(3,-8),vec2(1.5,-8)));d=min(d,line(p,vec2(1.5,-8),vec2(4.5,-8)));return d;}
//float J(vec2 p,float d){d=min(d,line(p,vec2(1.5,8),vec2(3,8)));d=min(d,line(p,vec2(3,8),vec2(4,7)));d=min(d,line(p,vec2(4,7),vec2(4,1.5)));d=min(d,line(p,vec2(4,1.5),vec2(1.5,1.5)));return d;}
//float K(vec2 p,float d){d=min(d,line(p,vec2(1,1.5),vec2(1,8)));d=min(d,line(p,vec2(1,8),vec2(1,5)));d=min(d,line(p,vec2(1,5),vec2(2.5,5)));d=min(d,line(p,vec2(2.5,5),vec2(5,1.5)));d=min(d,line(p,vec2(5,1.5),vec2(2.5,5)));d=min(d,line(p,vec2(2.5,5),vec2(5,8)));return d;}
//float L(vec2 p,float d){d=min(d,line(p,vec2(1,1.5),vec2(1,8)));d=min(d,line(p,vec2(1,8),vec2(5,8)));return d;}
float M(vec2 p,float d){d=min(d,line(p,vec2(1,-8),vec2(1,-1.5)));d=min(d,line(p,vec2(1,-1.5),vec2(3,-4)));d=min(d,line(p,vec2(3,-4),vec2(5,-1.5)));d=min(d,line(p,vec2(5,-1.5),vec2(5,-8)));return d;}
//float N(vec2 p,float d){d=min(d,line(p,vec2(1,8),vec2(1,1.5)));d=min(d,line(p,vec2(1,1.5),vec2(5,8)));d=min(d,line(p,vec2(5,8),vec2(5,1.5)));return d;}
//float O(vec2 p,float d){d=min(d,line(p,vec2(5,1.5),vec2(1,1.5)));d=min(d,line(p,vec2(1,1.5),vec2(1,8)));d=min(d,line(p,vec2(1,8),vec2(5,8)));d=min(d,line(p,vec2(5,8),vec2(5,1.5)));return d;}
//float P(vec2 p,float d){d=min(d,line(p,vec2(1,8),vec2(1,1.5)));d=min(d,line(p,vec2(1,1.5),vec2(5,1.5)));d=min(d,line(p,vec2(5,1.5),vec2(5,5)));d=min(d,line(p,vec2(5,5),vec2(1,5)));return d;}
//float Q(vec2 p,float d){d=min(d,line(p,vec2(5,8),vec2(5,1.5)));d=min(d,line(p,vec2(5,1.5),vec2(1,1.5)));d=min(d,line(p,vec2(1,1.5),vec2(1,8)));d=min(d,line(p,vec2(1,8),vec2(5,8)));d=min(d,line(p,vec2(5,8),vec2(3.5,6.5)));return d;}
float R(vec2 p,float d){d=min(d,line(p,vec2(1,-8),vec2(1,-1.5)));d=min(d,line(p,vec2(1,-1.5),vec2(5,-1.5)));d=min(d,line(p,vec2(5,-1.5),vec2(5,-5)));d=min(d,line(p,vec2(5,-5),vec2(1,-5)));d=min(d,line(p,vec2(1,-5),vec2(3.5,-5)));d=min(d,line(p,vec2(3.5,-5),vec2(5,-8)));return d;}
float S(vec2 p,float d){d=min(d,line(p,vec2(5,-1.5),vec2(1,-1.5)));d=min(d,line(p,vec2(1,-1.5),vec2(1,-5)));d=min(d,line(p,vec2(1,-5),vec2(5,-5)));d=min(d,line(p,vec2(5,-5),vec2(5,-8)));d=min(d,line(p,vec2(5,-8),vec2(1,-8)));return d;}
float T(vec2 p,float d){d=min(d,line(p,vec2(3,-8),vec2(3,-1.5)));d=min(d,line(p,vec2(3,-1.5),vec2(1,-1.5)));d=min(d,line(p,vec2(1,-1.5),vec2(5,-1.5)));return d;}
//float U(vec2 p,float d){d=min(d,line(p,vec2(1,1.5),vec2(1,8)));d=min(d,line(p,vec2(1,8),vec2(5,8)));d=min(d,line(p,vec2(5,8),vec2(5,1.5)));return d;}
//float V(vec2 p,float d){d=min(d,line(p,vec2(1,1.5),vec2(3,8)));d=min(d,line(p,vec2(3,8),vec2(5,1.5)));return d;}
//float W(vec2 p,float d){d=min(d,line(p,vec2(1,1.5),vec2(1,8)));d=min(d,line(p,vec2(1,8),vec2(3,6)));d=min(d,line(p,vec2(3,6),vec2(5,8)));d=min(d,line(p,vec2(5,8),vec2(5,1.5)));return d;}
//float X(vec2 p,float d){d=min(d,line(p,vec2(1,1.5),vec2(5,8)));d=min(d,line(p,vec2(5,8),vec2(3,4.75)));d=min(d,line(p,vec2(3,4.75),vec2(5,1.5)));d=min(d,line(p,vec2(5,1.5),vec2(1,8)));return d;}
float Y(vec2 p,float d){d=min(d,line(p,vec2(1,-1.5),vec2(3,-5)));d=min(d,line(p,vec2(3,-5),vec2(3,-8)));d=min(d,line(p,vec2(3,-8),vec2(3,-5)));d=min(d,line(p,vec2(3,-5),vec2(5,-1.5)));return d;}
//float Z(vec2 p,float d){d=min(d,line(p,vec2(1,1.5),vec2(5,1.5)));d=min(d,line(p,vec2(5,1.5),vec2(3,5)));d=min(d,line(p,vec2(3,5),vec2(1.5,5)));d=min(d,line(p,vec2(1.5,5),vec2(4.5,5)));d=min(d,line(p,vec2(4.5,5),vec2(3,5)));d=min(d,line(p,vec2(3,5),vec2(1,8)));d=min(d,line(p,vec2(1,8),vec2(5,8)));return d;}

float message(vec3 p)
{
    float d = 200.0;
    if (p.z>2.0)
        return d;
    float c = pMod1(p.z,26.0) * 25.0;        // * line offset
    p.x += time*7.0+c;
    pMod1(p.x, 120.0);
    
    float d2 = sdBox(p+vec3(0.0,-3.0,7.0),vec3(44.0,5.5,0.8));
    if (d2>8.0)
        return d;
    
    vec2 uv = p.xy;
    float x = -44.0;
    float y = 7.6+sin((time*4.0)+p.x*0.25)*0.7;
    float s = 5.8;
    uv-=vec2(x,y);
    
    d = M(uv,d); uv.x -= s;
    d = E(uv,d); uv.x -= s;
    d = R(uv,d); uv.x -= s;
    d = R(uv,d); uv.x -= s;
    d = Y(uv,d); uv.x -= s+s;
    d = C(uv,d); uv.x -= s;
    d = H(uv,d); uv.x -= s;
    d = R(uv,d); uv.x -= s;
    d = I(uv,d); uv.x -= s;
    d = S(uv,d); uv.x -= s;
    d = T(uv,d); uv.x -= s;
    d = M(uv,d); uv.x -= s;
    d = A(uv,d); uv.x -= s;
    d = S(uv,d);

    if (d<200.0)
    {
        // extrude
        float dep = 0.3;
        vec2 e = vec2( d, abs(p.z+7.0) - dep );
        d = min(max(e.x,e.y),0.0) + length(max(e,0.0));
        d -= 0.425;        // rounding
    }
    return d;
}

vec2 doModel( vec3 p )
{
    float d2 = sdPlane(p-vec3(0.0,-1.8,0.0));        // checkered floor distance...
    float dm = message(p);
    vec2 res = vec2(d2,0.0);            // distance,material index
    res = opUnionRound(res,vec2(dm,4.0),1.5);    
    return res;
}

vec3 hsv2rgb_smooth( in vec3 c )
{
    vec3 rgb = clamp( abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),6.0)-3.0)-1.0, 0.0, 1.0 );
    rgb = rgb*rgb*(3.0-2.0*rgb); // cubic smoothing    
    return c.z * mix( vec3(1.0), rgb, c.y);
}

//------------------------------------------------------------------------
// Material 
//
// Defines the material (colors, shading, pattern, texturing) of the model
// at every point based on its position and normal.
//------------------------------------------------------------------------
// c = colour index (added by del for some materials)
// c.a == specular val fudged in...
vec4 doMaterial( in vec3 pos, in vec3 nor,float c )
{
    if (c<=1.0)
    {
        // checker floor
    float f = mod( floor(0.125*pos.z) + floor(0.125*pos.x), 2.0) + 0.35;
        return f*vec4(0.331,0.725,0.951,0.0)*0.6;        
    }
    return vec4(hsv2rgb_smooth(vec3(-time*0.2+(pos.x+(pos.y*4.5))*0.0075,0.95,1.0))*0.5, 1.7);
}

//------------------------------------------------------------------------
// Lighting
//------------------------------------------------------------------------
float calcSoftshadow( in vec3 ro, in vec3 rd );

vec3 doLighting( in vec3 pos, in vec3 nor, in vec3 rd, in float dis, in vec4 mat )
{
    vec3 lin = vec3(0.0);

    // key light
    //-----------------------------
    vec3  lig = normalize(vec3(0.7,0.875,0.89));        // dir
    float dif = max(dot(nor,lig),0.0);
    float sha = 0.0;
    if( dif>0.01 )
        sha=calcSoftshadow( pos+0.01*nor, lig );
    lin += dif*vec3(1.00,1.00,1.00)*sha;
    float spec = pow(dif, 160.0) *mat.a;
    
    // ambient light
    //-----------------------------
    lin += vec3(0.50,0.50,0.50);
    
    // surface-light interacion
    //-----------------------------
    vec3 col = mat.xyz*lin;
    col+=spec;
    
    // fog    
    //-----------------------------
    col *= exp(-0.0001*dis*dis);
    return col;
}

vec2 calcIntersection( in vec3 ro, in vec3 rd )
{
    const float maxd = 180.0;           // max trace distance
    const float precis = 0.001;        // precission of the intersection
    float h = precis*2.0;
    float t = 0.0;
    vec2 res = vec2(-1.0,0.0);
    float c = 0.0;
    
    for( int i=0; i<100; i++ )          // max number of raymarching iterations is 100
    {
        if( h<precis||t>maxd ) break;
        vec2 res2 = doModel( ro+rd*t );
        h = res2.x;
        c = res2.y;
        
        t += h*0.75;
    }

    if( t<maxd )
    {
        res.x = t;
        res.y = c;
    }
    return res;
}

vec3 calcNormal( in vec3 pos )
{
    const float eps = 0.001;             // precision of the normal computation

    const vec3 v1 = vec3( 1.0,-1.0,-1.0);
    const vec3 v2 = vec3(-1.0,-1.0, 1.0);
    const vec3 v3 = vec3(-1.0, 1.0,-1.0);
    const vec3 v4 = vec3( 1.0, 1.0, 1.0);

    return normalize( v1*doModel( pos + v1*eps ).x + 
                      v2*doModel( pos + v2*eps ).x + 
                      v3*doModel( pos + v3*eps ).x + 
                      v4*doModel( pos + v4*eps ).x );
}

float calcSoftshadow( in vec3 ro, in vec3 rd )
{
    float res = 1.0;
    float t = 0.0005;                 // selfintersection avoidance distance
    float h = 1.0;
    for( int i=0; i<40; i++ )         // 40 is the max numnber of raymarching steps
    {
        h = doModel(ro + rd*t).x;
        res = min( res, 64.0*h/t );   // 64 is the hardness of the shadows
        t += clamp( h, 0.02, 2.0 );   // limit the max and min stepping distances
    }
    return clamp(res,0.0,1.0);
}

mat3 calcLookAtMatrix( in vec3 ro, in vec3 ta, in float roll )
{
    vec3 ww = normalize( ta - ro );
    vec3 uu = normalize( cross(ww,vec3(sin(roll),cos(roll),0.0) ) );
    vec3 vv = normalize( cross(uu,ww));
    return mat3( uu, vv, ww );
}

//snow original -> http://glslsandbox.com/e#36547.1
float snow(vec2 uv,float scale)
{
    float time = time*0.75;
    uv+=time/scale;
    uv.y+=time*2./scale;
    uv.x+=sin(uv.y+time*.5)/scale;
    uv*=scale;
    vec2 s=floor(uv);
    vec2 f=fract(uv);
    float k=3.0;
    vec2 p =.5+.35*sin(11.*fract(sin((s+scale)*mat2(7.0,3.0,6.0,5.0))*5.))-f;
    float d=length(p);
    k=min(d,k);
    k=smoothstep(0.,k,sin(f.x+f.y)*0.01);
    return k;
}

vec3 _Snow(vec2 uv,vec3 background)
{
    float c = snow(uv,30.)*.3;
    c+=snow(uv,20.)*.5;
    c+=snow(uv,15.)*.8;
    c+=snow(uv,10.);
    c+=snow(uv,8.);
    c+=snow(uv,6.);
    c+=snow(uv,5.);
    c = clamp(c,0.0,1.0);
    vec3 scol = vec3(1.0,1.0,1.0);
    scol = mix(background,scol,c);
    return scol;
}

void main(void)
{
    vec2 st = gl_FragCoord.xy/resolution.xy;
    vec2 p = (gl_FragCoord.xy * 2.0 - resolution.xy) / min(resolution.x, resolution.y);

    //-----------------------------------------------------
    // camera
    //-----------------------------------------------------
    vec3 ro, ta;
    doCamera( ro, ta, time);

    // camera matrix
    mat3 camMat = calcLookAtMatrix( ro, ta, 0.0 );  // 0.0 is the camera roll
    
    // create view ray
    vec3 rd = normalize( camMat * vec3(p.xy,2.0) ); // 2.0 is the lens length

    //-----------------------------------------------------
    // render
    //-----------------------------------------------------
    vec3 col = mix( vec3(0.2, 0.2, 0.2), vec3(0.0, 0.0, 0.1), gl_FragCoord.y / resolution.y )*0.4;

    // raymarch
    vec2 res = calcIntersection( ro, rd ); 
    float t = res.x;
    if( t>-0.5 )
    {
        // geometry
        vec3 pos = ro + t*rd;
        vec3 nor = calcNormal(pos);

        // materials
        vec4 mat = doMaterial( pos, nor, res.y );

        col = doLighting( pos, nor, rd, t, mat );
    }

    //-----------------------------------------------------
    // postprocessing
    //-----------------------------------------------------
    // gamma
    col = pow( clamp(col,0.0,1.0), vec3(0.4545) );
    col = _Snow(p.xy*0.5,col);
    glFragColor = vec4(col,1.);    
}
// thank god, its the end of the terrible shader...

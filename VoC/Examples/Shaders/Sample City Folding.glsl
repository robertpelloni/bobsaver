#version 420

// original https://www.shadertoy.com/view/wdVcRD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// A quick shadertoy port of City Shader from MagicaVoxel - original by mode_vis / paulofalcao
// using sabs for the folds as suggested by ollj

#define AA 1

float box(vec3 r, vec3 p, vec3 size)
{
    r = abs(r-p) - size;
    return max(max(r.x,r.y),r.z);
}

float sphere(vec3 r,vec3 p, float radius)
{
    return length(r-p) - radius;
}

float cylinder(vec3 r,vec3 p, float radius, float height)
{
    return max(length(r.xy-p.xy) - radius, abs(r.z-p.z)-height);
}
mat2 rot(float a)
{
    float c=cos(a),s=sin(a);
    return mat2(c,s,-s,c);
}

#define less(a,b,c)      mix(a,b,step(0.,c))
#define sabs(x,k) less((.5/k)*x*x+k*.5,abs(x),abs(x)-k)

vec3 Folding(vec3 p)
{
    p *= -0.3;
    
    float f = 2.65;
    float ic = 0.0;
    //if (mouse*resolution.xy.z>0.5)
    //{
    //    f+=sin(time*0.7);
    //    ic  = sin(time*1.2)*0.1;
    //}
    
    
    
    float s=3.;
    for(int i=0;i<10;i++)
    {
        p.xy=sabs(p,0.01).xy-s;
        p.xy *= rot(f*0.1);
        p.xz *= rot(ic*0.1);
        s=s/1.3;
    }
    
    return p;
}

float map( in vec3 p )
{
    
    float d = cylinder(p.xzy,vec3(0.0),4.75,1.0);
    
    p.yz*=rot(3.14*0.5);
    
    
    p = Folding(p);
    p += .05;
    
    vec3 pos1 = p;
    pos1.x = abs(p.x);
    vec3 pos2 = p;
    
    p.xy = abs(p.xy);
    
    
    float sdf = 0.;
    sdf = box(p,vec3(0.0,0.0,-0.1),vec3(2.,10.0,0.1));
    sdf = min(sdf,box(p,vec3(0.08,0.08,0.0),vec3(0.05,0.05,0.004)));
    sdf = max(sdf,-box(p,vec3(0.08,0.08,0.0),vec3(0.045,0.045,0.0025)));
    sdf = max(sdf,-box(p,vec3(0.0,0.0,0.0),vec3(0.02,10.0,0.002)));
    sdf = max(sdf,-box(p,vec3(0.0,0.0,0.0),vec3(10.,0.02,0.002)));
    sdf = max(sdf,-box(p,vec3(0.15,0.0,0.0),vec3(0.01,10.0,0.002)));
    sdf = max(sdf,-box(p,vec3(0.0,0.15,0.0),vec3(10.,0.01,0.002)));

    vec3 b1 = p;
    b1.xy -= vec2(0.22,0.08);
    b1 = abs(b1);
    float XYsize =  max(0.0,.5*p.z-0.02);
    float Zsize =  max(0.,0.4*max(b1.x,b1.y)-0.008);
    sdf = min(sdf,box(b1,vec3(-0.0,0.,0.0),vec3(0.05-XYsize,0.05-XYsize,0.06-Zsize)));
    sdf = max(sdf,-box(b1,vec3(0.0,0.0,0.052),vec3(0.02+XYsize,0.02+XYsize,0.05)));
    sdf = min(sdf,box(b1,vec3(0.02,0.04,0.046),vec3(0.005,0.009,0.007)));
    sdf = min(sdf,box(b1,vec3(0.04,0.02,0.05),vec3(0.004,0.002,0.006)));
    b1.xy *= 0.56;
    b1 = abs(b1-0.02);
    sdf = max(sdf,-box(b1,vec3(0.01,0.01,0.01),vec3(0.003,0.003,0.008)));

    vec3 b0 = pos1;
    b0.xy -= 0.08;
    b0=abs(b0);
    sdf = min(sdf,box(b0,vec3(0.,0.,0.005),vec3(0.05,0.05,0.005)));
    sdf = max(sdf,-box(b0,vec3(0.,0.,0.006),vec3(0.048,0.048,0.005)));
    sdf = min(sdf,box(b0,vec3(0.052,0.052,0.0),vec3(0.001,0.001,0.04)));
    sdf = min(sdf,box(b0,vec3(0.052,0.052,0.04),vec3(0.005,0.001,0.001)));
    float noise = 1.+0.05*length(sin(p*2000.0))+0.2*length(sin(p*900.0)); 
    b0.xy = abs(b0.xy);
    b0.xy -= 0.02;
    b0.xy = abs(b0.xy);
    b0 -= vec3(0.01,0.01,0.02);
    sdf = min(sdf,cylinder(b0,vec3(0.,0.,-0.015),0.001,0.009));
    b0*=noise;
    sdf = min(sdf,sphere(b0,vec3(0.),0.007));
    sdf = min(sdf,sphere(b0,vec3(0.,0.,-.006),0.011));

    vec3 b2 = p;
    b2.xy -= 0.22;
    b2 = abs(b2);
    sdf =  min(sdf,box(b2,vec3(0.,0.,0.0),vec3(0.05,0.03,0.1)));
    sdf = min(sdf,box(b2,vec3(0.,0.,0.04),vec3(0.04,0.05,0.01)));
    sdf = min(sdf,box(b2,vec3(0.,0.,0.07),vec3(0.04,0.05,0.01)));
    sdf = min(sdf,box(b2,vec3(0.,0.,0.1),vec3(0.04,0.05,0.01)));
    sdf = min(sdf,box(b2,vec3(0.,0.,0.05),vec3(0.02,0.02,0.1)));
    sdf = min(sdf,box(b2,vec3(0.052,0.052,0.0),vec3(0.001,0.001,0.04)));
    sdf = min(sdf,box(b2,vec3(0.052,0.052,0.04),vec3(0.005,0.001,0.001)));
    sdf = min(sdf,box(b2,vec3(0.,0.,0.03),vec3(0.03,0.04,0.1)));
    sdf = max(sdf,-box(b2,vec3(0.,0.,0.025),vec3(0.03,0.025,0.1)));

    vec3 b3 = pos2;
    b3.xy -=  vec2(0.08,0.-0.08);
    b3 = abs(b3);
    sdf = min(sdf,box(b3,vec3(0.,0.,0.053),vec3(0.045,0.045,0.008)));
    sdf = min(sdf,box(b3,vec3(0.,0.,0.033),vec3(0.04,0.04,0.033)));
    sdf = max(sdf,-box(b3,vec3(0.,0.0,0.064),vec3(0.04,0.04,0.006)));
    sdf = min(sdf,box(b3,vec3(0.,0.,0.02),vec3(0.051,0.051,0.002)));
    sdf = min(sdf,box(b3,vec3(0.,0.,0.04),vec3(0.051,0.051,0.002)));
    sdf = max(sdf,-box(b3,vec3(0.016,0.,0.033),vec3(0.01,0.051,0.003)));
    sdf = max(sdf,-box(b3,vec3(0.,0.016,0.033),vec3(0.051,0.01,0.003)));
    sdf = max(sdf,-box(b3,vec3(0.016,0.,0.053),vec3(0.01,0.051,0.003)));
    sdf = max(sdf,-box(b3,vec3(0.,0.016,0.053),vec3(0.051,0.01,0.003)));
    sdf = max(sdf,-box(b3,vec3(0.,0.016,0.003),vec3(0.051,0.01,0.003)));
    sdf = min(sdf,box(b3,vec3(0.05,0.05,0.0),vec3(0.001,0.001,0.04)));

    vec3 b4 = pos2;
    b4.xy -= vec2(0.08,0.-0.22);
    b4 = abs(b4);
    sdf = min(sdf,box(b4,vec3(0.,0.,0.003),vec3(0.051,0.051,0.003)));
    sdf = max(sdf,-box(b4,vec3(0.,0.,0.004),vec3(0.049,0.049,0.004)));
    sdf = min(sdf,box(b4,vec3(0.05,0.05,0.0),vec3(0.001,0.001,0.04)));
    sdf = min(sdf,box(b4,vec3(0.05,0.05,0.04),vec3(0.005,0.001,0.001)));
    sdf = max(sdf,-box(b4,vec3(0.,0.,0.004),vec3(0.052,0.01,0.004)));
    vec3 cone = b4;
    vec3 stairs = b4;
    sdf = min(sdf,cylinder(b4,vec3(0.008,0.008,0.015),0.0005,0.006));
    cone.xy += (cone.z-0.021);
    sdf = min(sdf,cylinder(cone,vec3(0.,0.,0.026),0.015,0.006));
    stairs.xy += floor(stairs.z * 800.0)/800.0;
    sdf = min(sdf,box(stairs,vec3(0.008,0.008,0.0),vec3(0.02,0.02,0.01)));

    vec3 b5 = pos2;
    b5.xy -= vec2(-0.08,0.-0.22);
    b5 = abs(b5);
    sdf = min(sdf,box(b5,vec3(0.014,0.0018,0.0),vec3(0.002,0.001,0.03)));
    sdf = min(sdf,box(b5,vec3(0.01,0.0018,0.03),vec3(0.015,0.001,0.001)));
    sdf = min(sdf,box(b5,vec3(0.02,0.0018,0.032),vec3(0.015,0.001,0.001)));
    sdf = min(sdf,box(b5,vec3(0.01,0.0018,0.024),vec3(0.015,0.001,0.001)));
    sdf = min(sdf,box(b5,vec3(0.04,0.01,0.0),vec3(0.01,0.016,0.01)));
    sdf = min(sdf,sphere(b5,vec3(0.04,0.04,0.004),0.004));
    sdf = min(sdf,sphere(b5,vec3(0.04,0.04,0.010),0.006));
    sdf = min(sdf,box(b5,vec3(0.052,0.052,0.0),vec3(0.001,0.001,0.04)));
    sdf = min(sdf,box(b5,vec3(0.052,0.052,0.04),vec3(0.005,0.001,0.001)));

    sdf = max(sdf,d);
    
    return sdf;
}

// http://iquilezles.org/www/articles/normalsSDF/normalsSDF.htm
vec3 calcNormal( in vec3 pos )
{
    vec2 e = vec2(1.0,-1.0)*0.5773;
    const float eps = 0.001;
    return normalize( e.xyy*map( pos + e.xyy*eps ) + 
                      e.yyx*map( pos + e.yyx*eps ) + 
                      e.yxy*map( pos + e.yxy*eps ) + 
                      e.xxx*map( pos + e.xxx*eps ) );
}
    

void main(void)
{
     // camera movement    
    float an = 0.125*time;
    vec3 ro = vec3( 6.0*cos(an), .8+sin(time)*0.4, 6.0*sin(an) );
    vec3 ta = vec3( 0.0, 0.0, 0.0 );
    // camera matrix
    vec3 ww = normalize( ta - ro );
    vec3 uu = normalize( cross(ww,vec3(0.0,1.0,0.0) ) );
    vec3 vv = normalize( cross(uu,ww));

    
    
    vec3 tot = vec3(0.0);
    
    #if AA>1
    for( int m=0; m<AA; m++ )
    for( int n=0; n<AA; n++ )
    {
        // pixel coordinates
        vec2 o = vec2(float(m),float(n)) / float(AA) - 0.5;
        vec2 p = (-resolution.xy + 2.0*(gl_FragCoord.xy+o))/resolution.y;
        #else    
        vec2 p = (-resolution.xy + 2.0*gl_FragCoord.xy)/resolution.y;
        #endif

        // create view ray
        vec3 rd = normalize( p.x*uu + p.y*vv + 1.8*ww );

        // raymarch
        const float tmax = 30.0;
        float t = 0.0;
        for( int i=0; i<256; i++ )
        {
            vec3 pos = ro + t*rd;
            float h = map(pos);
            if( h<0.0001 || t>tmax ) break;
            t += h;
        }
    
        // shading/lighting
        float v = 1.0-abs(p.y);
        vec3 col = vec3(v*0.1);
        if( t<tmax )
        {
            vec3 pos = ro + t*rd;
            vec3 nor = calcNormal(pos);
            
            vec3 ldir = normalize(vec3(0.5,0.2,0.4));
            
            float dif = clamp( dot(nor,ldir), 0.0, 1.0 );
            float amb = 0.5 + 0.5*dot(nor,vec3(0.0,0.8,0.6));
            col = vec3(0.2,0.2,0.2)*amb + vec3(0.8,0.7,0.5)*dif;
               col+= pow(dif, 40.);

        }

        // gamma        
        col = sqrt( col );
        tot += col;
    #if AA>1
    }
    tot /= float(AA*AA);
    #endif

    glFragColor = vec4( tot, 1.0 );
}

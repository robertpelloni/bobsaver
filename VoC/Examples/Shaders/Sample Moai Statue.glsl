#version 420

// original https://www.shadertoy.com/view/tttXWf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// A very badly modelled Moai statue :) - Del 16/02/2020

#define AA 2
#define PI        3.1415926

float opSmoothUnion( float d1, float d2, float k ) {
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h); }

float opSmoothSubtraction( float d1, float d2, float k ) {
    float h = clamp( 0.5 - 0.5*(d2+d1)/k, 0.0, 1.0 );
    return mix( d2, -d1, h ) + k*h*(1.0-h); }
float opSubtraction( float d1, float d2 ) { return max(-d1,d2); }

float sdCone(vec3 p, vec3 a, vec3 b, float ra, float rb)
{
    float rba  = rb-ra;
    float baba = dot(b-a,b-a);
    float papa = dot(p-a,p-a);
    float paba = dot(p-a,b-a)/baba;

    float x = sqrt( papa - paba*paba*baba );

    float cax = max(0.0,x-((paba<0.5)?ra:rb));
    float cay = abs(paba-0.5)-0.5;

    float k = rba*rba + baba;
    float f = clamp( (rba*(x-ra)+paba*baba)/k, 0.0, 1.0 );

    float cbx = x-ra - f*rba;
    float cby = paba - f;
    
    float s = (cbx < 0.0 && cay < 0.0) ? -1.0 : 1.0;
    
    return s*sqrt( min(cax*cax + cay*cay*baba,
                       cbx*cbx + cby*cby*baba) );
}
float smin( float a, float b, float k )
{
    float h = max( k-abs(a-b), 0.0 )/k;
    return min( a, b ) - h*h*k*(1.0/4.0);
}
float sdBox( vec3 p, vec3 b )
{
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}
float mouth (in vec3 p)
{
    vec3 mouthpos = p-vec3(0.0,-0.4,0.10);    
    float body = length (mouthpos);
    float size = 0.15;
    body = max (body - size,  -body);
    float Angle = PI * ( 0.1 * abs(sin (time*3.0)));
    float mouthT = dot (mouthpos, vec3 (0.0, -cos (Angle), sin (Angle)));
    Angle *= 2.4;
    float mouthB = dot (mouthpos, vec3 (0.0, cos (Angle), sin (Angle)));
    return max (body, min (mouthT, mouthB));
}
float ear (in vec3 p)
{
    p.y += 0.15;
    p.z -= 0.02;
    float d1 =  sdCone(p, vec3(0.22,-0.2,0.0), vec3(0.19,0.2,0.0), 0.02,0.01 );
    float d2 =  sdCone(p, vec3(-0.22,-0.2,0.0), vec3(-0.19,0.2,0.0), 0.02,0.01 );
    return min(d1,d2);
}

mat2 rotate(float a)
{
    float c = cos(a);
    float s = sin(a);
    return mat2(c, s, -s, c);
}
float map( in vec3 pos )
{
    
    //pos.xz *= rotate(sin(time+pos.y));
    pos.x = mod(pos.x,0.6)-0.3;
    
    pos.y -= 0.2;
    float d1 =  sdCone(pos, vec3(0.0,-0.5,0.0), vec3(0.0,0.2,0.0), 0.225, 0.16 );
    float d7 = mouth(pos);
    d1 = smin(d1,d7,0.15);
    float d3 = sdBox(pos+vec3(0.0,0.15,-0.4),vec3(0.2,0.15,0.3));
    d1 = opSmoothSubtraction(d3,d1,0.025);        // box cutout
    vec3 q = pos+vec3(0.0,0.0,-0.08);    //-vec3(0.0,0.0,-0.1);
    float d2 =  sdCone(q, vec3(0.0,0.0,0.04), vec3(0.0,-0.3,0.105), 0.1*0.4, 0.1*0.9 );
    d1 = smin(d1,d2,0.045);
    float d4 = sdBox(pos+vec3(0.0,0.1,0.15),vec3(0.2,0.5,0.1));
    d1 = opSmoothSubtraction(d4,d1,0.09);        // box cutout
    
    float ep = ear(pos);
    d1 = smin(ep,d1,0.05);
    
    return d1;
}

vec3 calcNormal( in vec3 pos )
{
    vec2 e = vec2(1.0,-1.0)*0.5773;
    const float eps = 0.0005;
    return normalize( e.xyy*map( pos + e.xyy*eps ) + 
                      e.yyx*map( pos + e.yyx*eps ) + 
                      e.yxy*map( pos + e.yxy*eps ) + 
                      e.xxx*map( pos + e.xxx*eps ) );
}
    

void main(void)
{
       vec2 uv = (2. * gl_FragCoord.xy - resolution.xy) / resolution.y;

//    vec
     // camera movement    
    float an = sin(time)*0.8;
    an+=3.14*0.5;
    float y = 0.0;
    
    //if (mouse*resolution.xy.z>0.5)
    //{
    //    an=mouse*resolution.xy.x/resolution.x*4.0;
    //    y = (mouse*resolution.xy.y/resolution.y)*2.0;
    //    y-=1.0;
    //}
    
    vec3 ro = vec3( 1.0*cos(an), y, 1.0*sin(an) );
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
        vec3 rd = normalize( p.x*uu + p.y*vv + 1.5*ww );

        // raymarch
        const float tmax = 8.0;
        float t = 0.0;
        for( int i=0; i<80;i++ )
        {
            vec3 pos = ro + t*rd;
            float h = map(pos);
            if( h<0.0001 || t>tmax ) break;
            t += h;
        }
        
    
        // shading/lighting    
        vec3 col = vec3(0.6,0.4,0.4*abs(sin(uv.x*0.1+time)))*1.0-abs(uv.y*0.5);
        if( t<tmax )
        {
            vec3 pos = ro + t*rd;
            vec3 nor = calcNormal(pos);
            float dif = clamp( dot(nor,vec3(0.57703)), 0.0, 1.0 );
            float amb = 0.5 + 0.5*dot(nor,vec3(0.0,1.0,0.0));
            vec3 ambcol = vec3(0.4,0.3,0.3)*amb;
            col = ambcol + vec3(0.6,0.55,0.85)*dif;
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

#version 420

// original https://www.shadertoy.com/view/Ws3yWn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Added some colour+blend for fun

#define AA 1    // make this 2 if you are feeling cold...
#define HEIGHT 8.

vec3 _col = vec3(0.0);    // pure filth
// prim
float sdCylinder( vec3 p, vec2 h )
{
  vec2 d = abs(vec2(length(p.xz),p.y)) - h;
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}
// min/max polynomial
float smin( float a, float b, float k )
{
    float h = clamp( 0.5 + 0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}

float sminCol( float a, float b, float k, vec3 col1, vec3 col2 )
{
    float h = clamp( 0.5 + 0.5*(b-a)/k, 0.0, 1.0 );
    _col = mix(col1,col2,h);// -  k*h*(1.0-h);
    return mix( b, a, h ) - k*h*(1.0-h);
}
vec3 hsv2rgb(vec3 c)
{
  // Íñigo Quílez
  // https://www.shadertoy.com/view/MsS3Wc
  vec3 rgb = clamp(abs(mod(c.x*6.+vec3(0.,4.,2.),6.)-3.)-1.,0.,1.);
  rgb = rgb * rgb * (3. - 2. * rgb);
  return c.z * mix(vec3(1.), rgb, c.y);
}

float smax(float a, float b, float k)
{
    return smin(a, b, -k);
}
// noise
float noise(vec3 p,float scale, float s1,float s2)
{
    p*=scale;
    float k = dot(sin(p - cos(p.yzx*1.57)), vec3(.333))*s1;
    k += dot(sin(p*2. - cos(p.yzx*3.14)), vec3(.333))*s2;    
    return k*0.4;
}

float map( in vec3 pos )
{
    float rad =  (1.0/(3.141*2.0)*20.0);
    vec3 dp = vec3(pos.z, atan(pos.x, pos.y) * rad, rad-length(pos.xy));    
    float d1 = sdCylinder(dp,vec2(0.8,HEIGHT))-0.5;
    float t = time*1.35;
    float n1 = noise(dp+vec3(0.0,t*1.0,0.0),1.0,3.57,.83);
    float n2 = noise(dp+vec3(sin(t*.2)*2.0,t*1.5,0.0), 1.5, 4.47, 1.43);
    float n3 = noise(dp+vec3(0.0,t*2.0,0.0), 2.0, 1.87,3.13);
    n1 = smin(n1,n2,4.);
    n1 = smin(n1,n3,4.);
      d1 = smax(n1,d1,4.);
    
    n3 = noise(pos+vec3(0.0,t*2.0,0.0),1.0,3.57,1.83)*2.0;
    float disp = (sin(pos.z*1.3+t*1.1+pos.x*0.4)+cos(n3+t*1.3+pos.z*1.5+sin(t*2.2+pos.x*1.25)))*0.1;
    
    float d2 = dot(pos,vec3(0.0,1.0,0.0)) + 1.5+disp;   
    //d1 = smin(d1,d2,1.2);
    
    vec3 goo = hsv2rgb(vec3(t*0.2+dp.y*0.075,0.85,0.9));
    
    d1 = sminCol(d1,d2,1.2,vec3(0.025,0.2,0.75),goo);
    
    return d1*0.75;
}

vec3 calcNormal( in vec3 pos )
{
    vec2 e = vec2(1.0,-1.0)*0.5773;
    const float eps = 0.008;    //0.0005
    return normalize( e.xyy*map( pos + e.xyy*eps ) + 
                      e.yyx*map( pos + e.yyx*eps ) + 
                      e.yxy*map( pos + e.yxy*eps ) + 
                      e.xxx*map( pos + e.xxx*eps ) );
}
    
void main(void)
{
     // camera movement    
    float an = 0.2-sin(time*.75)*2.0;
    vec3 ro = vec3( 7.0*cos(an), 2.0+sin(time*0.75)*2.2, 7.0*sin(an) );
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
        const float tmax = 25.0;
        float t = 0.0;
        for( int i=0; i<160; i++ )
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
            
            vec3 dir = normalize(vec3(1.0,0.7,0.0));
            vec3 ref = reflect(rd, nor);
            float spe = max(dot(ref, dir), 0.0);
            vec3 spec = vec3(1.0) * pow(spe, 20.);
            float dif = clamp( dot(nor,dir), 0.05, 1.0 );
            col =  _col*dif;
            col+=spec;
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

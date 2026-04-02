#version 420

// original https://www.shadertoy.com/view/ttsfzS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.1415926535
#define TWO_PI 6.2831853

// Created by inigo quilez - iq/2014
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

const mat2 m = mat2( 0.80,  0.60, -0.60,  0.80 );

float hash( vec2 p )
{
    float h = dot(p,vec2(127.1,311.7));
    return -1.0 + 2.0*fract(sin(h)*43758.5453123);
}

float noise( in vec2 p )
{
    vec2 i = floor( p );
    vec2 f = fract( p );
    
    vec2 u = f*f*(3.0-2.0*f);

    return mix( mix( hash( i + vec2(0.0,0.0) ), 
                     hash( i + vec2(1.0,0.0) ), u.x),
                mix( hash( i + vec2(0.0,1.0) ), 
                     hash( i + vec2(1.0,1.0) ), u.x), u.y);
}

float fbm( vec2 p )
{
    float f = 0.0;
    f += 0.5000*noise( p ); p = m*p*2.02;
    f += 0.2500*noise( p ); p = m*p*2.03;
    f += 0.1250*noise( p ); p = m*p*2.01;
    f += 0.0625*noise( p );
    return f/0.9375;
}

vec2 fbm2( in vec2 p )
{
    return vec2( fbm(p.xy), fbm(p.yx) );
}

vec3 map1( vec2 p )
{   
    p *= 0.7;

    float f = dot( fbm2( 1.0*(0.05*time + p + fbm2(-0.05*time+2.0*(p + fbm2(4.0*p)))) ), vec2(1.0,-1.0) );

    float bl = smoothstep( -0.8, 0.8, f );

    float ti = smoothstep( -1.0, 1.0, fbm(p) );

    return mix( mix( vec3(0.50,0.00,0.00), 
                     vec3(1.00,0.75,0.35), ti ), 
                     vec3(0.00,0.00,0.02), bl );
}

float SmooSub( float d1, float d2, float k ) {
    float h = clamp( 0.5 - 0.5*(d2+d1)/k, 0.0, 1.0 );
    return mix( d2, -d1, h ) + k*h*(1.0-h); }

float smin(float a, float b, float k)
{
    float h = max(k-abs(a-b),0.0);
    return min(a,b) - h*h/(k*4.0);
}

float sRound(float a, float b, float r) {
    vec2 u = max(vec2(r - a,r - b), vec2(0));
    return max(r, min (a, b)) - length(u);
}

float pMod1(inout float p, float size) {
    float halfsize = size*0.5;
    float c = floor((p + halfsize)/size);
    p = mod(p + halfsize, size) - halfsize;
    return c;
}

float sphere(vec2 p,float size)
{
    return length(p)-size;
}

float smooU( float d1, float d2, float k ) {
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h); }

float Cylinder( vec3 p, float ra, float rb, float h )
{
  vec2 d = vec2( length(p.xz)-2.0*ra+rb, abs(p.y) - h );
  return min(max(d.x,d.y),0.0) + length(max(d,0.0)) - rb;
}

float Link( vec3 p, float le, float r1, float r2 )
{
  vec3 q = vec3( p.y, max(abs(p.y)-le,0.0), p.z );
  return length(vec2(length(q.xy)-r1,q.z)) - r2;
}

float torus( vec3 p, vec2 t )
{
  vec2 q = vec2(length(p.xz)-t.x,p.y);
  return length(q)-t.y;
}

float rBox( vec3 p, vec3 b, float r )
{
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0) - r;
}

float Prism( vec3 p, vec2 h )
{
  vec3 q = abs(p);
  return max(q.z-h.y,max(q.x*0.866025+p.y*0.5,-p.y)-h.x*0.5);
}

vec3 pR45(vec3 p) 
{
     vec3 pos = vec3(p + vec3(p.y, -p.x,0))*sqrt(0.5);
    return pos;
}

vec3 pR( vec3 p, float a) {
    vec3 pos = vec3(cos(a)*p + sin(a)*vec3(p.y, -p.x,0.0));
    return pos;
}

float sminCu( float a, float b, float k )
{
    float h = max( k-abs(a-b), 0.0 )/k;
    return min( a, b ) - h*h*h*k*(1.0/6.0);
}

vec2 map (vec3 pos)
{
    
    vec2 d1 = vec2(Cylinder(pos + vec3(0.69,0.01,1.6), 0.21,0.012,0.125),0.7); 
    
    vec2 d2 = vec2(Cylinder(pos + vec3(0.69,0.01,-1.6), 0.21,0.012,0.125),0.7); 
    
    //vec2 link1 = vec2(Link(pos + vec3(0.0,0.5,0.0), 0.7, 0.3,0.21),1.0);  
    
    float to = torus(pos+ vec3(-0.7,0.15,0.0), vec2(0.4,0.2));
    vec2 link1 = vec2( to ,1.0);  
    
    float sp = sphere(pos.xz,0.5);
    
    float rbo = rBox(pos+ vec3(-0.9,0.25,-1.68), vec3(0.116,0.2,0.3),0.11);
    
    float rbo2 = rBox(pos+ vec3(-0.9,0.25,1.68), vec3(0.116,0.2,0.3),0.11);
    
   // float f = dot( fbm2( 1.0*(0.05*time + pos.xy + fbm2(-0.05*time+2.0*(pos.zx + fbm2(4.0*pos.zx)))) ), vec2(1.0,-1.0) );
    
    vec2 colc = fbm2( 0.05*time+pos.xy+ fbm2(-0.05*time-2.0*(pos.zx)) ) *0.15;
    
    vec2 cola = 1.0*(0.05*time + pos.xy + fbm2(-0.05*time+2.0*(pos.zx + fbm2(4.0*pos.zx)))) ;
    
   //  d1.x = pMod1(pos.y,1.01);

    //float d2 = pos.y;
    
     //float d0 = smooU(pos.y+colc.x, pos.y,0.01);
    float d0 = sminCu(pos.y+colc.x, pos.y,0.05+0.05*abs(sin(time*0.5)));
    //float d3 = smooU(colc.y*0.01,pos.y,0.3);
    float d3 = smooU(d1.x,d0,0.3);
    
    
    
    float d4 = smooU(d2.x,d0,0.3);
    
    float dist = smin(d4,d3,0.009);
    
    //float l1 = smooU(link1.x,dist,0.06);
    
    float l1 = smooU(rbo,d0,0.1+0.04*abs(cos(time)));
   // float l2 = smooU(rbo2,l1,0.06);
    
   // float pri = Prism(pR(pos.xzy+vec3(-1,0,0.2),12.05)+vec3(0.,0.0,0.), vec2(0.05,0.01));
    
    float pri = torus(pos+vec3(0.,0.05,0.0),vec2(0.628,0.01));
    
    float l2 = smooU(pri,l1,0.1+0.04*abs(sin(time)));
    float l3 = smooU(rbo2,l2,0.1+0.04*abs(cos(time)));
    
   // float l4 = smooU(l3,l2,0.0);
    
    float d = smin(l3,dist,0.009);
    
   
    
   // return (d3<d1.x) ? vec2(d3,1.0) : d1;
   // return colc;
   // return colc;
    return vec2(d,1.0);//+(colc*0.01);
}

vec3 calcNormal(vec3 pos)
{
    vec2 e = vec2(0.0001,0.0); 
    return normalize(vec3(map(pos+e.xyy).x-map(pos-e.xyy).x,
                         map(pos+e.yxy).x-map(pos-e.yxy).x,
                         map(pos+e.yyx).x-map(pos-e.yyx).x
                         ));
}

float castShadow(vec3 ro,vec3 rd)
{
    float res = 1.0;
    float t = 0.001;
    for (int i = 0; i <100; i++)
    {
        vec3 pos = ro+t*rd;
        float h = map(pos).x;
        res = min(res, 16.0*h/t);
        if(h<0.0001)break;
        t += h;
        if (t>20.0)break;
        
    }
    return clamp(res,0.0,1.0);
}

vec2 marchRay (vec3 ro, vec3 rd)
{
    float m = -1.0;
    float t = 0.0;
    for (int i = 0; i < 100; i++)
    {
       vec3 pos = ro+t*rd;
        
       vec2 h = map(pos);
        m = h.y;
       if (h.x<0.001)
           break;
        t+=h.x;
        if (t>20.0) break;    
    }
    
    if (t>20.0) m=-1.0;
    return vec2(t,m);
}

vec4 circle(vec2 uv, vec2 pos, float rad, vec3 color) {
    float d = length(pos - uv) - rad;
    float t = clamp(d, 0.0, 1.0);
    return vec4(color, 1.0 - t);
}

void main(void)
{
  
    vec2 p = (2.0*gl_FragCoord.xy-resolution.xy)/resolution.y;
    
    //float f = smoothstep(0.25,0.26,length(p));
    float an = 0.0; //5.0*mouse.y*resolution.xy.y/resolution.y;
    vec3 ta = vec3(0.0,1.0,0.0);

   // vec3 ro = ta+vec3(1.5*sin(an),1.5*cos(an),0.); // Ray origin - 2 back in z direction
    vec3 ro = ta+vec3(0.02,2.0,0.0); // Ray origin - 2 back in z direction
    
    vec3 ww = normalize(ta-ro);
    vec3 uu = normalize(cross(ww,vec3(0,1,0)));
    vec3 vv = normalize(cross(uu,ww));
    vec3 rd = normalize(vec3(p.x*uu + p.y*vv +1.9*ww)); // ray detect, becomes length of camera 
    vec3 col = vec3(0.1,0.1,1.0) - 0.7*rd.y;
    col = mix(col, vec3(0.1,0.75,0.1),exp(-10.0*rd.y));
    

      vec2 tm = marchRay(ro,rd);
    
    
    if (tm.y>0.0)
    {
        float t = tm.x;
        vec3 pos = ro  + t*rd;
        vec3 nor = calcNormal(pos);
        
        vec3 matte = vec3(0.18);
        
        if (tm.y<1.5)
        {
            matte = vec3(0.09,0.09,0.09);
           // float f = -2.0+2.0*smoothstep(-0.2,0.2,sin(2.0*pos.x)+sin(2.0*pos.y)+sin(2.0*pos.z));
            
            float f = -1.0+2.0*smoothstep(-0.05,0.04,-pos.x);
            
           // matte+=0.3*f*vec3(0.12,0.12,0.12);
            
            matte+=0.3*vec3(0.1,0.12,0.12);
            
        }

        
        else if (tm.y<2.5)
        {
           // matte = vec3(0.2,0.1,0.2);
        }
        
        
        else //if (tm.y<3.5)
        {
          //  matte = vec3(0.4,0.4,0.4);
        }
        
        
    
        col = vec3(0.03,0.03,0.03);
       // float f = sin(18.0*pos.x)*sin(18.0*pos.z);
      //     col+=f;
        vec3 sun_dir = normalize(vec3(0.02,0.022,0.01));
        //vec3 sun_dir = normalize(vec3(0.5*sin(time*0.2)+0.1,0.1+0.1*abs(sin(time*0.2)),abs(sin(time*0.02))));
        float sun_dif = clamp (dot(nor,sun_dir),0.0,1.0);
        float sun_sha = castShadow(pos+nor*0.001,sun_dir);
        float sky_dif = sqrt(clamp(0.5+0.5*dot(nor,vec3(0.0,1.0,0.0)),0.0,1.0));
        float bou_dif = clamp(0.5+0.5*dot(nor,vec3(0.0,-1.0,0.0)),0.0,1.0);
        
        
        col = matte*sun_dif*vec3(0.2,0.2,0.2); 
        col += matte*sky_dif*vec3(0.5,0.8,0.9);
        //col += matte*vec3(0.7,0.3,0.2)*bou_dif;
        
        vec3 lin = vec3(0.0);
        lin += sun_dif*vec3(7.0,4.5,5.0); // key light
        lin += sky_dif*vec3(0.5,0.8,0.9);
        
        lin += matte*vec3(0.7,0.3,0.2)*bou_dif;
        col = col*lin;
    }
    
    col = pow(col,vec3(0.4545));
    
    vec2 uv3 = gl_FragCoord.xy;
    float radius = 0.25 * resolution.y;
    vec2 center = resolution.xy * 0.5;
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    vec2 uv2 = (gl_FragCoord.xy-0.5*resolution.xy)/resolution.y;
    // the sound texture is 512x2
    //uv2+=0.5;
    uv2 *=0.5;

    vec2 p1 = (-resolution.xy+2.0*gl_FragCoord.xy)/resolution.y;
    p1*=2.;

    float e = 0.0045;

    vec3 colc = map1( p1               ); float gc = dot(colc,vec3(0.233));
    vec3 cola = map1( p1 + vec2(e,0.0) ); float ga = dot(cola,vec3(0.233));
    vec3 colb = map1( p1 + vec2(0.0,e) ); float gb = dot(colb,vec3(0.233));
    
    vec3 nor = normalize( vec3(ga-gc, e, gb-gc ) );

    vec3 col1 = colc;
    col1 += vec3(0.0,0.7,0.6)*1.0*abs(2.0*gc-ga-gb);
    col1 *= 1.0+0.2*nor.y*nor.y;
    col1 += 0.05*nor.y*nor.y*nor.y;
    
    
    vec2 q = gl_FragCoord.xy/resolution.xy;
    col1 *= pow(16.0*q.x*q.y*(1.0-q.x)*(1.0-q.y),0.1);
    
    vec4 fragCo = vec4( col1, 1.0 );
    
    
    vec3 red = vec3(fragCo.rgb);
    vec4 cc = circle(uv3,center,radius*0.7,red);
    // Output to screen
    glFragColor = mix(vec4(col,1.0), cc, mix(0.0,1.0*abs(sin(time*0.2)),0.5*sin(time*0.2)));;
   // glFragColor = mix(vec4(col,1.0), cc, mix(cc.a,0.0,0.));
    
     //glFragColor = mix(vec4(col,1.0), cc, 0.4);
    
    //glFragColor = vec4(col,1.0);
   // glFragColor = mix(vec4(col,1.0), cc, mix(cc.a,0.5,1.*abs(sin(time*0.2))));;
}


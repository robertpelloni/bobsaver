#version 420

// original https://www.shadertoy.com/view/MtXGRN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

const int MaxIter = 16;
const int maxSteps =256;
float zoom=1.;
float preci;
float flapTime;

// Complex operations

vec2 cmul( vec2 a, vec2 b )  { return vec2( a.x*b.x - a.y*b.y, a.x*b.y + a.y*b.x ); }
vec2 csqr( vec2 a )  { return vec2( a.x*a.x - a.y*a.y, 2.*a.x*a.y  ); }
vec2 conj( vec2 z ) { return vec2(z.x,-z.y); }

// Exotic multiplication

vec4 dmul( vec4 a, vec4 b )  {
    float r = length(a);    
    b.xy=cmul(normalize(a.xy), b.xy);
    b.xz=cmul(normalize(a.xz), b.xz);
    b.zw=cmul(normalize(a.zw), b.zw);
    return r*b;
}

// Distance estimation for fractal

float de( vec3 p)
{    
    float dr = 1.;    
    p*=dr;
    float r2;
    vec4 z = vec4(-p.yzx,0.2); 
    dr=dr/length(z);
    if(z.z>-0.5)z.x+=.5*flapTime*abs(z.y)*(z.z+.5);  
    dr=dr*length(z);      
    vec4 c= z;
    for( int i=0; i<MaxIter;i++ )
    {                           
        r2 = dot(z,z);
        if(r2>100.)continue;
        dr=2.*sqrt(r2)*dr+1.0;            
        z=dmul(z,z)+c;                 
    }
    return .5*length(z)*log(length(z))/dr;            
}

    
// Orbit trapping for fractal
    
vec4 map(in vec3 p)
{
    float dr = 1.0;
    vec4 ot = vec4(1000.0);        
    float r2;
    vec4 z = vec4(-p.yzx,0.2);
    if(z.z>-0.5)z.x+=.5*flapTime*abs(z.y)*(z.z+.5);         
    vec4 c= z;
    for( int i=0; i<MaxIter;i++ )
    {            
        r2 = dot(z,z);
        if(r2>100.)continue;        
        ot = min( ot, vec4(abs(z.xyz),r2) );       
        dr=2.*sqrt(r2)*dr+1.0;            
        z=dmul(z,z)+c;                            
    }            
    return ot;    
}

float field(in vec3 p, inout float ot) {
    float dr = 1.0;      
    float r2;
    float res = 0.;
    vec4 z = vec4(-p.yzx,0.2);
    dr=dr/length(z);
    if(z.z>-0.5)z.x+=.5*flapTime*abs(z.y)*(z.z+.5);  
    dr=dr*length(z);  
    vec4 c = z;
    for (int i = 0; i < MaxIter; ++i) {
        
        r2 = dot(z,z);
        if(r2>100.)continue;
        dr=2.*sqrt(r2)*dr+1.0;    
        z=dmul(z,z)+c;
        if(i<10)res += 2.*exp(-3. * abs(dot(z,c)));
        
    }
    ot = res/4.;
    return .5*length(z)*log(length(z))/dr;    
}

vec4 raymarch( in vec3 ro, vec3 rd, vec2 tminmax   )
{
    float t = tminmax.x;
    vec3 col= vec3(0.);
    float ot;
    float dt = 1.; 
    for( int i=0; i<maxSteps; i++ )   
    {
        if( t>tminmax.y || dt<=preci*t ) continue;
        dt = field(ro+t*rd,ot);
        t+=dt;
        float c = max(5.0 * ot - .9, 0.0);
        col = .95*col+ .08*vec3(0.5*c*c*c, .6*c*c, c);
        
    }
    if(t>tminmax.y||dt>preci*t*1.)return vec4(col,-1.);
    return vec4(col,t);
}

vec3 calcNormal( in vec3 pos )
{
    vec3  delta = vec3(.0001,0.0,0.0);
    vec3 nor;   
    nor.x = de(pos+delta.xyy) - de(pos-delta.xyy);
    nor.y = de(pos+delta.yxy) - de(pos-delta.yxy);
    nor.z = de(pos+delta.yyx) - de(pos-delta.yyx);   
    return normalize(nor);
}

void main(void)
{
    preci =  .5/min(resolution.x,resolution.y);
    flapTime = cos(time);

    vec2 q = gl_FragCoord.xy / resolution.xy;
    vec2 p = -1.0 + 2.0*q;
    p.x *= resolution.x/ resolution.y;
    //vec2 mo = iMouse.xy / iResolution.xy;
    vec2 mo = vec2(0.0,0.0);
    float an = 2.0 + 0.05*time - mo.x+180.;
    
    vec3  light1 = vec3(  0.577, 0.577, -0.577 );
    vec3  light2 = vec3( -0.707, 0.000,  0.707 );

    vec3 ro = zoom*1.7*vec3(sin(an),0.+0.8*cos(1.3*an+mo.y), cos(an));
    vec3 ta = vec3(cos(an),0.0, sin(an));
    vec3 ww = normalize( ta - ro);
    vec3 uu = normalize( cross( vec3(0.0,1.0,0.0), ww ) );
    vec3 vv = normalize( cross(ww,uu) );
    vec3 rd = normalize( p.x*uu + p.y*vv + 1.0*ww );

    vec3 col = vec3(0.05);
    float t;
    vec2 seg= vec2(0.,30.);;

      
    vec4 rm = raymarch( ro, rd, seg );
    t=rm.a;
    seg = vec2(2.,t);
    vec3 col2 = vec3(0.);
    if(t<0.)col2 = rm.rgb;
    if(t>=0.){
         //col2=.05*rm.rgb;
        
        vec3 pos = ro+ t* rd;
        vec4 res = map( pos);
        vec3 col1 =clamp(res.xyz,0.,1.);
        col1=.5*(col1+col1.brg);
        col1.g+=col1.r;              
        vec3 nor = calcNormal( pos);
  

        // lighting
        
        float key = clamp( dot( light1, nor ), 0.0, 1.0 );
        float bac = clamp( 0.2 + 0.8*dot( light2, nor), 0.0, 1.0 );
        float amb = (0.7+0.3*nor.y);
        float ao = pow( clamp(res.a*2.0,0.2,1.0), 2.2 );        
        vec3 brdf = vec3(ao)*(.4*amb+1.5*key+.2*bac);
        
        col = col1*brdf;
        
        }       
    col = pow( col, vec3(0.4) ) * 1.2+col2*.4;
    col *= sqrt( 16.0*q.x*q.y*(1.0-q.x)*(1.0-q.y) );
        
    glFragColor = vec4( col, 1.0 );
}

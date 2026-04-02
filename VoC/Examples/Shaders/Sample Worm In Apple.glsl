#version 420

// original https://www.shadertoy.com/view/MdVGDw

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// madeBy@MMGS 2016

void doCamera( out vec3 camPos, out vec3 camTar, in float time, in float mouseX )
{
    float an =  3.1+mouse.x*resolution.x*0.1;
    camPos = vec3(5.5*sin(an),1.0,5.5*cos(an));
    camTar = vec3(0.0,0.0,0.0);
}

vec3 doBackground( vec2 uv)
{
    return vec3(0,0,0.5-uv.y);
}
    
float sMin( float a, float b )
{
    float k = .12;
    float h = clamp(0.5 + 0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.-h);
}

//functions that build rotation matrixes
mat2 rotate_2D(float a){float sa = sin(a); float ca = cos(a); return mat2(ca,sa,-sa,ca);}
mat3 rotate_x(float a){float sa = sin(a); float ca = cos(a); return mat3(1.,.0,.0,    .0,ca,sa,   .0,-sa,ca);}
mat3 rotate_y(float a){float sa = sin(a); float ca = cos(a); return mat3(ca,.0,sa,    .0,1.,.0,   -sa,.0,ca);}
mat3 rotate_z(float a){float sa = sin(a); float ca = cos(a); return mat3(ca,sa,.0,    -sa,ca,.0,  .0,.0,1.);}

float sdCappedCylinder( vec3 p, vec2 h )
{
    
  vec2 d = abs(vec2(length(p.xz),p.y)) - h;
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}
float udBox( vec3 p, vec3 b )
{
  return length(max(abs(p)-b,0.0));
}
vec2 doModel( vec3 p )
{
     float id;
    
    vec3 music;// = texture2D(iChannel0,p.xz).xyz;
    
    float scene[19]; //array to hold scene objects
    float s,s1,s2;
   // vec3 hpos=vec3(0.+cos(p.y+time*4.)*p.x*0.005,0,0); //model position
 
    s=1.0;
    p.x+=1.5;
    // p+=hpos;
        for(int i=0;i<15;i++)
    {
        float iter = float(i)*0.1;
      if(i<12) p.z -= sin(time+p.x*3.1)*0.06;
         s2 = length(p+vec3(.0-iter  ,iter ,0) ) - .15-cos(p.x*13.1)*0.04;      
        s=sMin(s,s2);scene[0] = s-0.01;
        if(i<12)  p.z += sin(time+p.x*3.1)*0.06;
        
  
    }
     p.z+=cos(time)*0.1;
       //nose
        s2 = length(p+vec3(0.35,0,0) ) - .32;
         s=sMin(s,s2);scene[1] = sMin(s,s2);
    
       for(int i=0;i<2;i++)
    {
          float iter = float(i)*0.022;

      s2 = length(p+vec3(.65-iter*2.,-0.1,0.1) ) - .035;
         s=max(s,-s2);scene[2] = s+0.1;
          s2 = length(p+vec3(.65-iter*2.,-0.1,-0.1) ) - .035;
         s=max(s,-s2);scene[2] = s+0.1;
     
    }
    //cheek
      s2 = length(p+vec3(0.1,-0.1,0.3) ) - .3;
         s=sMin(s,s2);scene[3] = sMin(s,s2);
  
     s2 = length(p+vec3(0.1,-0.1,-0.3) ) - .3;
         s=sMin(s,s2);scene[4] = sMin(s,s2);
    //eyesockets
     s2 = length(p+vec3(0.1,-0.4,0.15) ) - .25;
         s=sMin(s,s2);scene[5] =sMin(s,s2);
      s2 = length(p+vec3(0.1,-0.4,-0.15) ) - .25;
         s=sMin(s,s2);scene[6] =sMin(s,s2);
   
    //eyes
       s2 = length(p+vec3(0.15,-0.4,0.15) ) - .2;
         s=sMin(s,s2);scene[8] =sMin(s,s2);
      s2 = length(p+vec3(0.15,-0.4,-0.15) ) - .2;
         s=sMin(s,s2);scene[9] =sMin(s,s2);
   //  p.z-=cos(time)*0.1;
    
 
       s2 = length(p+vec3(0.35,-0.4,0.15) ) - .02;
         s=sMin(s,s2);scene[11] =sMin(s,s2);
      s2 = length(p+vec3(0.35,-0.4,-0.15) ) - .02;
         s=sMin(s,s2);scene[12] =sMin(s,s2);
    
     p.z-=cos(time)*0.1;
    
    
    //apple
    p.x+=-2.9;
    p.y -= 0.75*pow(0.01+dot(p.xz,p.xz),0.2);
   vec2 d1 = vec2( length(p+vec3(0,2.5,0)) - 1.5, 1.0 );
   
    s=sMin(s,d1.x); scene[7] =sMin(s,d1.x)+0.02;
    
    
            for(int i=0;i<5;i++)
    {
        float
        
         iter = float(i)*0.05;
          s2 = length(p+vec3(iter*1.2  ,1.1-iter*3. ,0) ) - .07-cos(p.x*13.1)*0.1*-p.x*0.5;      
        s=sMin(s,s2);scene[10] = s2-0.5;
        
    }
    
      //////SORT OBJECTS
    float test=9999.0;  //return closest object in scene
    for(int i=0;i<13;i++){
        float test2=scene[i];
        if(test2<test)test=test2;
    }
    
    
    if(test == scene[0])id=1.0;
     if(test == scene[1])id=1.0;
      if(test == scene[2])id=1.0;
    if(test == scene[3])id=1.0;
    if(test == scene[4])id=1.0;
    if(test == scene[5])id=1.0;
    if(test == scene[6])id=1.0;
    if(test == scene[7])id=2.0;
    if(test == scene[8])id=5.0;
    if(test == scene[9])id=5.0;
    if(test == scene[10])id=4.0;
     if(test == scene[11])id=3.0;
     if(test == scene[12])id=3.0;
    return vec2(s,id);
}
mat3 m = mat3( 0.00,  0.80,  0.60,
              -0.80,  0.36, -0.48,
              -0.60, -0.48,  0.64 );
float hash( float n )
{
    return fract(sin(n)*43758.5453);
}

float noise( in vec3 x )
{
    vec3 p = floor(x);
    vec3 f = fract(x);

    f = f*f*(3.0-2.0*f);

    float n = p.x + p.y*57.0 + 113.0*p.z;

    float res = mix(mix(mix( hash(n+  0.0), hash(n+  1.0),f.x),
                        mix( hash(n+ 57.0), hash(n+ 58.0),f.x),f.y),
                    mix(mix( hash(n+113.0), hash(n+114.0),f.x),
                        mix( hash(n+170.0), hash(n+171.0),f.x),f.y),f.z);
    return res;
}

float fbm( vec3 p )
{
    float f = 0.0;

    f += 0.5000*noise( p ); p = m*p*2.02;
    f += 0.2500*noise( p ); p = m*p*2.03;
    f += 0.1250*noise( p ); p = m*p*2.01;
    f += 0.0625*noise( p );

    return f/0.9375;
}

vec3 appleColor( in vec3 pos, in vec3 nor, out vec2 spe )
{
    spe.x = 1.0;
    spe.y = 1.0;

    float a = atan(pos.x,pos.z);
    float r = length(pos.xz);

    // red
    vec3 col = vec3(2.0,0.0,0.0);

    // green
    float f = smoothstep( 0.1, 1.0, fbm(pos*1.0) );
    col = mix( col, vec3(0.8,1.0,0.2), f );

    // dirty
    f = smoothstep( 0.0, 1.0, fbm(pos*4.0) );
    col *= 0.8+0.2*f;

    // frekles
    f = smoothstep( 0.0, 1.0, fbm(pos*48.0) );
    f = smoothstep( 0.7,0.9,f);
    col = mix( col, vec3(0.9,0.9,0.6), f*0.5 );

    // stripes
    f = fbm( vec3(a*7.0 + pos.z,3.0*pos.y,pos.x)*2.0);
    f = smoothstep( 0.2,1.0,f);
    f *= smoothstep(0.4,1.2,pos.y + 0.75*(noise(4.0*pos.zyx)-0.5) );
    col = mix( col, vec3(0.4,0.2,0.0), 0.5*f );
    spe.x *= 1.0-0.35*f;
    spe.y = 1.0-0.5*f;

    // top
    f = 1.0-smoothstep( 0.14, 0.2, r );
    col = mix( col, vec3(0.6,0.6,0.5), f );
    spe.x *= 1.0-f;

    float ao = 0.5 + 0.5*nor.y;
    col *= ao*1.;

    return col;
}
vec3 doMaterial( in vec3 pos, in vec3 nor,vec2 obj )
{
    vec3 col = vec3(0.2,0.25,0.2);
     vec3  lig = normalize(vec3(-1.0,0.7,-0.9));
    float spec = pow(clamp(dot(lig,nor),0.0,1.),6.0);
   
    vec2 apl;
    
    if(obj.y==1.) col =  vec3(0.1,0.7,0.1)*appleColor(nor,nor, apl );
    if(obj.y==2.) col =  mix(appleColor(pos,nor, apl )*vec3(3,2.1,1)*0.3, vec3(spec*0.8)-dot(nor,lig)*0.4,  0.2);
    if(obj.y==3.) col =  vec3(0,0,0)+spec*0.1;
    if(obj.y==4.) col =  vec3(155./255.,103./255.,43./255.)*appleColor(nor,nor, apl )*0.3;
    if(obj.y==5.) col =  vec3(0.27);
    if(obj.y==6.) col = vec3(0.0); //texture2D(iChannel1,pos.xz*1.5+0.5 ).xyz*0.5;
    return col;
}

//------------------------------------------------------------------------
// Lighting
//------------------------------------------------------------------------
float calcSoftshadow( in vec3 ro, in vec3 rd );

vec3 doLighting( in vec3 pos, in vec3 nor, in vec3 rd, in float dis, in vec3 mal )
{
    vec3 lin = vec3(0.);

    // key light
    //-----------------------------
    vec3  lig = normalize(vec3(-1.0,0.7,-0.9));
    float dif = max(dot(nor,lig),0.0);
    float sha = 0.0; if( dif>0.01 ) sha=calcSoftshadow( pos+0.01*nor, lig );
    lin += dif*vec3(4.00,4.00,4.00)*sha;

    // ambient light
    //-----------------------------
    lin += vec3(0.50,0.50,0.50);

    
    // surface-light interacion
    //-----------------------------
    vec3 col = mal*lin;

    
    // fog    
    //-----------------------------
    col *= exp(-0.001*dis);

    return col;
}

float calcIntersection( in vec3 ro, in vec3 rd )
{
    const float maxd = 10.0;           // max trace distance
    const float precis = 0.001;        // precission of the intersection
    float h = precis*2.0;
    float t = 0.0;
    float res = -1.0;
    for( int i=0; i<80; i++ )          // max number of raymarching iterations is 90
    {
        if( h<precis||t>maxd ) break;
        h = doModel( ro+rd*t ).x;
        t += h;
    }

    if( t<maxd ) res = t;
    return res;
}

vec3 calcNormal( in vec3 pos )
{
    const float eps = 0.002;             // precision of the normal computation

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
    for( int i=0; i<25; i++ )         // 40 is the max numnber of raymarching steps
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

void main(void)
{
    vec2 p = (-resolution.xy + 2.0*gl_FragCoord.xy)/resolution.y;
    vec2 m = mouse*resolution.xy.xy/resolution.xy;

    //-----------------------------------------------------
    // camera
    //-----------------------------------------------------
    
    // camera movement
    vec3 ro, ta;
    doCamera( ro, ta, time, m.x );

    // camera matrix
    mat3 camMat = calcLookAtMatrix( ro, ta, 0.0 );  // 0.0 is the camera roll
    
    // create view ray
    vec3 rd = normalize( camMat * vec3(p.xy,1.8) ); // 2.0 is the lens length

    //-----------------------------------------------------
    // render
    //-----------------------------------------------------

    vec3 col = doBackground(gl_FragCoord.xy/resolution.xy);

    // raymarch
    float t = calcIntersection( ro, rd );
    if( t>-0.5 )
    {
        // geometry
        vec3 pos = ro + t*rd;
        vec3 nor = calcNormal(pos);
        
        vec2 obj = doModel(pos);
        // materials
       vec3 mal = doMaterial( pos, nor, obj );
        //vec3 obj = doModel(p);
        col = doLighting( pos, nor, rd, t, mal );
    }

    //-----------------------------------------------------
    // postprocessing
    //-----------------------------------------------------
    // gamma
    col = pow( clamp(col,0.0,1.0), vec3(0.4545) );
       
    glFragColor = vec4( col, 1.0 );
}

#version 420

// original https://www.shadertoy.com/view/XlyBRG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define R resolution.xy
#define T (time*0.5)

#define texScaleFactor 15.0

//    Simplex 4D Noise 
//    by Ian McEwan, Ashima Arts
//
vec4 permute(vec4 x){return mod(((x*34.0)+1.0)*x, 289.0);}
float permute(float x){return floor(mod(((x*34.0)+1.0)*x, 289.0));}
vec4 taylorInvSqrt(vec4 r){return 1.79284291400159 - 0.85373472095314 * r;}
float taylorInvSqrt(float r){return 1.79284291400159 - 0.85373472095314 * r;}

vec4 grad4(float j, vec4 ip){
  const vec4 ones = vec4(1.0, 1.0, 1.0, -1.0);
  vec4 p,s;

  p.xyz = floor( fract (vec3(j) * ip.xyz) * 7.0) * ip.z - 1.0;
  p.w = 1.5 - dot(abs(p.xyz), ones.xyz);
  s = vec4(lessThan(p, vec4(0.0)));
  p.xyz = p.xyz + (s.xyz*2.0 - 1.0) * s.www; 

  return p;
}

float snoise(vec4 v){
  const vec2  C = vec2( 0.138196601125010504,  // (5 - sqrt(5))/20  G4
                        0.309016994374947451); // (sqrt(5) - 1)/4   F4
// First corner
  vec4 i  = floor(v + dot(v, C.yyyy) );
  vec4 x0 = v -   i + dot(i, C.xxxx);

// Other corners

// Rank sorting originally contributed by Bill Licea-Kane, AMD (formerly ATI)
  vec4 i0;

  vec3 isX = step( x0.yzw, x0.xxx );
  vec3 isYZ = step( x0.zww, x0.yyz );
//  i0.x = dot( isX, vec3( 1.0 ) );
  i0.x = isX.x + isX.y + isX.z;
  i0.yzw = 1.0 - isX;

//  i0.y += dot( isYZ.xy, vec2( 1.0 ) );
  i0.y += isYZ.x + isYZ.y;
  i0.zw += 1.0 - isYZ.xy;

  i0.z += isYZ.z;
  i0.w += 1.0 - isYZ.z;

  // i0 now contains the unique values 0,1,2,3 in each channel
  vec4 i3 = clamp( i0, 0.0, 1.0 );
  vec4 i2 = clamp( i0-1.0, 0.0, 1.0 );
  vec4 i1 = clamp( i0-2.0, 0.0, 1.0 );

  //  x0 = x0 - 0.0 + 0.0 * C 
  vec4 x1 = x0 - i1 + 1.0 * C.xxxx;
  vec4 x2 = x0 - i2 + 2.0 * C.xxxx;
  vec4 x3 = x0 - i3 + 3.0 * C.xxxx;
  vec4 x4 = x0 - 1.0 + 4.0 * C.xxxx;

// Permutations
  i = mod(i, 289.0); 
  float j0 = permute( permute( permute( permute(i.w) + i.z) + i.y) + i.x);
  vec4 j1 = permute( permute( permute( permute (
             i.w + vec4(i1.w, i2.w, i3.w, 1.0 ))
           + i.z + vec4(i1.z, i2.z, i3.z, 1.0 ))
           + i.y + vec4(i1.y, i2.y, i3.y, 1.0 ))
           + i.x + vec4(i1.x, i2.x, i3.x, 1.0 ));
// Gradients
// ( 7*7*6 points uniformly over a cube, mapped onto a 4-octahedron.)
// 7*7*6 = 294, which is close to the ring size 17*17 = 289.

  vec4 ip = vec4(1.0/294.0, 1.0/49.0, 1.0/7.0, 0.0) ;

  vec4 p0 = grad4(j0,   ip);
  vec4 p1 = grad4(j1.x, ip);
  vec4 p2 = grad4(j1.y, ip);
  vec4 p3 = grad4(j1.z, ip);
  vec4 p4 = grad4(j1.w, ip);

// Normalise gradients
  vec4 norm = taylorInvSqrt(vec4(dot(p0,p0), dot(p1,p1), dot(p2, p2), dot(p3,p3)));
  p0 *= norm.x;
  p1 *= norm.y;
  p2 *= norm.z;
  p3 *= norm.w;
  p4 *= taylorInvSqrt(dot(p4,p4));

// Mix contributions from the five corners
  vec3 m0 = max(0.6 - vec3(dot(x0,x0), dot(x1,x1), dot(x2,x2)), 0.0);
  vec2 m1 = max(0.6 - vec2(dot(x3,x3), dot(x4,x4)            ), 0.0);
  m0 = m0 * m0;
  m1 = m1 * m1;
  return 49.0 * ( dot(m0*m0, vec3( dot( p0, x0 ), dot( p1, x1 ), dot( p2, x2 )))
               + dot(m1*m1, vec2( dot( p3, x3 ), dot( p4, x4 ) ) ) ) ;

}

//https://github.com/hughsk/glsl-hsv2rgb/blob/master/index.glsl
vec3 hsv2rgb(vec3 c) {
  vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
  vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
  return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

float terrainHeight(vec2 pos){
    //return snoise(vec4(pos.x*0.1,pos.y*0.1,T,0.0));
    //return cos(pos.x);
    return 0.0;
    //vec4 p=texture(iChannel0,mod(pos/texScaleFactor,1.0));
    //p*=pow(1.0-mod(pos.y/texScaleFactor,1.0),40.0);
    //return p.x*4.0;
}

float map(vec3 p){
    //return p.y-terrainHeight(p.xz);
    
    //The below is incorrect but good-looking
    return 0.1;//Uncomment line 17 to see the real terrain
}

vec3 camPos(){
    vec2 p=8.0*vec2(cos(T),sin(T));
    return vec3(p.x,5.0,p.y);
    //return vec3(2.1,5.0,0.0);
}

#define camUp  vec3(0.0,1.0,0.0)
#define lookAt vec3(0.0,0.0,0.0)
#define zoom   1.0

vec3 cam_dir(vec2 uv){
    uv*=2.0;
    uv-=1.0;    
    uv.x*=R.x/R.y;
    
    vec3 f=normalize(lookAt-camPos());
    vec3 r=cross(camUp,f);
    vec3 u=cross(f,r);
    
    return normalize(f*zoom+r*uv.x+u*uv.y);
}

float intersect(vec3 ro,vec3 rd){
    float t=0.0;
    float endt=0.001;
    float maxt=20000.0;
    int maxi=40;
    int i=0;
    for(i=0;i<maxi;i++){
        float d=map(ro);
        ro+=rd*d;
        t+=d;
        if(ro.y<terrainHeight(ro.xz))return t;
        if(t>maxt)return -1.0;
    }
    return t;
}

vec3 terrainShade(vec3 pos){
    //return vec3(0.5+0.5*sin(pos.y));
    //return 0.5+0.5*sin(pos);
    return 0.5+0.5*vec3(snoise(vec4(pos,0.0+T)),snoise(vec4(pos,1.0+T)),snoise(vec4(pos,2.0+T)));
    //vec4 p=texture(iChannel0,mod(pos.xz/texScaleFactor,1.0));
    //vec3 c= 0.5+0.5*vec3(sin(p.x));
    //return hsv2rgb(vec3(c.x,0.5,1.0));
}

vec3 phongShade(vec3 norm,vec3 amb,vec3 diff,vec3 spec,float shin,vec3 hit,vec3 cam,vec3 light){
    return spec*clamp(pow(dot(reflect(normalize(hit-light),norm),normalize(cam-hit)),shin),0.0,1.0)+diff*clamp(dot(norm,normalize(light-hit)),0.0,1.0)+amb;
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/R;

    vec3 dir=cam_dir(uv);
    
    float t=intersect(camPos(),dir);
    //if(t==-1.0){
        //vec4 p=texture(iChannel0,vec2(0.0));
        //glFragColor=sin(p*20.0)*0.5+0.5;
      //  return;
    //}
    
    vec3 hitPoint=camPos()+t*dir;
    
    vec3 shaded=terrainShade(hitPoint);

    vec3 col=shaded;
    if(col.x>1.0||col.y>1.0||col.z>1.0)col/=max(col.x,max(col.y,col.z));
    glFragColor=vec4(col,1.0);
}

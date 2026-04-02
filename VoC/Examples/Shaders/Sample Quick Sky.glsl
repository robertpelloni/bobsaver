#version 420

// original https://www.shadertoy.com/view/3dXBR8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//    Simplex 3D Noise 
//    by Ian McEwan, Ashima Arts
//
vec4 permute(vec4 x){return mod(((x*34.0)+1.0)*x, 289.0);}
vec4 taylorInvSqrt(vec4 r){return 1.79284291400159 - 0.85373472095314 * r;}

float snoise(vec3 v){ 
  const vec2  C = vec2(1.0/6.0, 1.0/3.0) ;
  const vec4  D = vec4(0.0, 0.5, 1.0, 2.0);

// First corner
  vec3 i  = floor(v + dot(v, C.yyy) );
  vec3 x0 =   v - i + dot(i, C.xxx) ;

// Other corners
  vec3 g = step(x0.yzx, x0.xyz);
  vec3 l = 1.0 - g;
  vec3 i1 = min( g.xyz, l.zxy );
  vec3 i2 = max( g.xyz, l.zxy );

  //  x0 = x0 - 0. + 0.0 * C 
  vec3 x1 = x0 - i1 + 1.0 * C.xxx;
  vec3 x2 = x0 - i2 + 2.0 * C.xxx;
  vec3 x3 = x0 - 1. + 3.0 * C.xxx;

// Permutations
  i = mod(i, 289.0 ); 
  vec4 p = permute( permute( permute( 
             i.z + vec4(0.0, i1.z, i2.z, 1.0 ))
           + i.y + vec4(0.0, i1.y, i2.y, 1.0 )) 
           + i.x + vec4(0.0, i1.x, i2.x, 1.0 ));

// Gradients
// ( N*N points uniformly over a square, mapped onto an octahedron.)
  float n_ = 1.0/7.0; // N=7
  vec3  ns = n_ * D.wyz - D.xzx;

  vec4 j = p - 49.0 * floor(p * ns.z *ns.z);  //  mod(p,N*N)

  vec4 x_ = floor(j * ns.z);
  vec4 y_ = floor(j - 7.0 * x_ );    // mod(j,N)

  vec4 x = x_ *ns.x + ns.yyyy;
  vec4 y = y_ *ns.x + ns.yyyy;
  vec4 h = 1.0 - abs(x) - abs(y);

  vec4 b0 = vec4( x.xy, y.xy );
  vec4 b1 = vec4( x.zw, y.zw );

  vec4 s0 = floor(b0)*2.0 + 1.0;
  vec4 s1 = floor(b1)*2.0 + 1.0;
  vec4 sh = -step(h, vec4(0.0));

  vec4 a0 = b0.xzyw + s0.xzyw*sh.xxyy ;
  vec4 a1 = b1.xzyw + s1.xzyw*sh.zzww ;

  vec3 p0 = vec3(a0.xy,h.x);
  vec3 p1 = vec3(a0.zw,h.y);
  vec3 p2 = vec3(a1.xy,h.z);
  vec3 p3 = vec3(a1.zw,h.w);

//Normalise gradients
  vec4 norm = taylorInvSqrt(vec4(dot(p0,p0), dot(p1,p1), dot(p2, p2), dot(p3,p3)));
  p0 *= norm.x;
  p1 *= norm.y;
  p2 *= norm.z;
  p3 *= norm.w;

// Mix final noise value
  vec4 m = max(0.6 - vec4(dot(x0,x0), dot(x1,x1), dot(x2,x2), dot(x3,x3)), 0.0);
  m = m * m;
  return 42.0 * dot( m*m, vec4( dot(p0,x0), dot(p1,x1), 
                                dot(p2,x2), dot(p3,x3) ) );
}

vec3 skyColor( vec3 cameraRay, vec3 sunDirection, bool nosun ){
    vec3 skyColor = vec3( 1.0, 1.2, 1.7 );
    
    float sunHeight = (sunDirection.y + 1.0 ) * 0.5;
    float hozHeight = clamp(smoothstep(-0.2,1.0,sunHeight),0.0,1.0);
    
    float hozHeightAbs = clamp(smoothstep(0.2,1.0,sunHeight), 0.0,1.0)+0.01;
    float eyeHeight = clamp(( cameraRay.y + 0.1 ),0.0,1.0 ) ;
    
    vec3 sunColor = mix( vec3(1.2,0.0,0.0), vec3(0.95,0.95,0.7), hozHeightAbs );
    
    float sunDot = pow( ( dot( cameraRay, sunDirection ) + 1.0 ) * 0.5, 2000.0*pow(eyeHeight,2.0)+1.0);
    
    vec3 sunGlow = sunColor * sunDot * hozHeightAbs;
    
    vec3 skyGlow = skyColor * hozHeightAbs;
    
    float stars = clamp(smoothstep(0.8,1.0,snoise(cameraRay*100.0)),0.0,1.0)*0.3 * clamp(smoothstep(0.1,0.5,cameraRay.y),0.0,1.0) * clamp(smoothstep(0.1,-0.1,sunDirection.y),0.0,1.0);
    
    float ground = pow(1.0-clamp(-cameraRay.y,0.0,1.0),20.0);
    
    
    float fog = pow( 1.0 - abs(cameraRay.y), 2.0 )*(hozHeight+0.2);
     
    vec3 col = skyGlow*0.4 + sunGlow*0.9 + stars + fog*sunColor*0.1*hozHeight;
    
    vec3 groundColor = vec3(0.09,0.1,0.08) * clamp( sunDirection.y, 0.0,1.0 ) * sunColor * 2.0;
 
    if(cameraRay.y<0.0){
        col= mix(groundColor, col, ground); 
    }
    
    if(!nosun){
        float sun = clamp(smoothstep(0.9995,0.9996,dot( cameraRay, sunDirection )),0.0,1.0) * clamp(smoothstep(0.0,0.1,cameraRay.y),0.0,1.0)*0.3;
        col+=sun*sunColor;
    }
    
    return col;
}

float cloudValue( vec3 cloudCoord ){
    float time = time * 0.1;
    cloudCoord.z+=time;
    float cloud = snoise(cloudCoord)*0.55+snoise(cloudCoord*2.0+time*0.3)*0.2+snoise(cloudCoord*4.0+time*0.2)*0.2+snoise(cloudCoord*8.0+time*0.5)*0.05+snoise(cloudCoord*16.0)*0.05;
    cloud = ( cloud + 1.0 ) * 0.5;
    return cloud;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy/resolution.xy - 0.5 ) * 2.0;
    
    vec2 mouse = vec2(0.0,0.1);//1.0-( mouse*resolution.xy.xy/resolution.xy - 0.5 ) * 2.0;
    
    float aspect = resolution.x/resolution.y;
    
    uv.x*=aspect;
    
    vec3 sunDirection = normalize( vec3( 0.0,sin(time*0.2)*1.0,1.0) );
    
    vec3 cameraRay = normalize( vec3(uv, 2.0) );
    
    mat2 rotx = mat2( cos( mouse.y * 3.14159 ),-sin( mouse.y * 3.14159 ),sin( mouse.y * 3.14159 ),cos( mouse.y * 3.14159 ) );
    cameraRay.yz = rotx * cameraRay.yz;
    
    mat2 roty = mat2( cos( mouse.x * 3.14159 ),-sin( mouse.x * 3.14159 ),sin( mouse.x * 3.14159 ),cos( mouse.x * 3.14159 ) );
    cameraRay.xz = roty * cameraRay.xz;
    
        
        
    vec3 col = skyColor( cameraRay, sunDirection, false );
    
    vec3 cloudCoord = cameraRay / (cameraRay.y + 0.2 ) * 0.5;
    
    float cloud = cloudValue( cloudCoord );
    
    vec3 normal = vec3( cloudValue(cloudCoord + vec3(0.1,0.0,0.0)), cloudValue(cloudCoord + vec3(0.0,0.1,0.0)), cloudValue(cloudCoord + vec3(0.0,0.0,0.1))  );
    normal -= cloud;
    normalize(normal);
    normal.y = abs(normal.y);
                       
    
    vec3 cloudColor = vec3(cloud);
    
    float cloudCover = 0.2;
    
    if( cameraRay.y > 0.0 ){
        cloud = clamp(cloud-pow(1.0-abs(cameraRay.y),50.0)*0.5,0.0,1.0);
        vec3 sunColor = skyColor( sunDirection, sunDirection, true );
        float sunLighting = pow( dot( -normal, sunDirection ) + 1.0, 3.0 );
        float cloudLuma = pow( clamp(sunDirection.y,0.0,1.0),0.8);
        vec3 cloudColor = sunLighting * sunColor * cloudLuma;
        float cloudmix = clamp(smoothstep((0.8 - cloudCover*2.0),1.0,cloud),0.0,1.0);
        col = mix(col, cloudColor,pow(cloudmix,(0.8 - cloudCover) * 2.0));

    }
    
    col = pow(col,vec3(0.5));
    glFragColor = vec4(col,1.0);
}

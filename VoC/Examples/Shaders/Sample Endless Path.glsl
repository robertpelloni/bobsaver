#version 420

// original https://www.shadertoy.com/view/WtfSD7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 mod3D289( vec3 x ) { return x - floor( x / 289.0 ) * 289.0; }
vec4 mod3D289( vec4 x ) { return x - floor( x / 289.0 ) * 289.0; }
vec4 permute( vec4 x ) { return mod3D289( ( x * 34.0 + 1.0 ) * x ); }
vec4 taylorInvSqrt( vec4 r ) { return 1.79284291400159 - r * 0.85373472095314; }
//simplex noise3D
float snoise( vec3 v )
{
    const vec2 C = vec2( 1.0 / 6.0, 1.0 / 3.0 );
    vec3 i = floor( v + dot( v, C.yyy ) );
    vec3 x0 = v - i + dot( i, C.xxx );
    vec3 g = step( x0.yzx, x0.xyz );
    vec3 l = 1.0 - g;
    vec3 i1 = min( g.xyz, l.zxy );
    vec3 i2 = max( g.xyz, l.zxy );
    vec3 x1 = x0 - i1 + C.xxx;
    vec3 x2 = x0 - i2 + C.yyy;
    vec3 x3 = x0 - 0.5;
    i = mod3D289( i);
    vec4 p = permute( permute( permute( i.z + vec4( 0.0, i1.z, i2.z, 1.0 ) ) + i.y + vec4( 0.0, i1.y, i2.y, 1.0 ) ) + i.x + vec4( 0.0, i1.x, i2.x, 1.0 ) );
    vec4 j = p - 49.0 * floor( p / 49.0 );  // mod(p,7*7)
    vec4 x_ = floor( j / 7.0 );
    vec4 y_ = floor( j - 7.0 * x_ );  // mod(j,N)
    vec4 x = ( x_ * 2.0 + 0.5 ) / 7.0 - 1.0;
    vec4 y = ( y_ * 2.0 + 0.5 ) / 7.0 - 1.0;
    vec4 h = 1.0 - abs( x ) - abs( y );
    vec4 b0 = vec4( x.xy, y.xy );
    vec4 b1 = vec4( x.zw, y.zw );
    vec4 s0 = floor( b0 ) * 2.0 + 1.0;
    vec4 s1 = floor( b1 ) * 2.0 + 1.0;
    vec4 sh = -step( h, vec4(0.0) );
    vec4 a0 = b0.xzyw + s0.xzyw * sh.xxyy;
    vec4 a1 = b1.xzyw + s1.xzyw * sh.zzww;
    vec3 g0 = vec3( a0.xy, h.x );
    vec3 g1 = vec3( a0.zw, h.y );
    vec3 g2 = vec3( a1.xy, h.z );
    vec3 g3 = vec3( a1.zw, h.w );
      vec4 norm = taylorInvSqrt( vec4( dot( g0, g0 ), dot( g1, g1 ), dot( g2, g2 ), dot( g3, g3 ) ) );
    g0 *= norm.x;
    g1 *= norm.y;
    g2 *= norm.z;
    g3 *= norm.w;
    vec4 m = max( 0.6 - vec4( dot( x0, x0 ), dot( x1, x1 ), dot( x2, x2 ), dot( x3, x3 ) ), 0.0 );
    m = m* m;
    m = m* m;
    vec4 px = vec4( dot( x0, g0 ), dot( x1, g1 ), dot( x2, g2 ), dot( x3, g3 ) );
    return 42.0 * dot( m, px);
}

float sdf_Cylinder( vec3 p, float h, float r )
{
  vec2 d = abs(vec2(length(p.xz),p.y)) - vec2(h,r);
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

float sdf_plane(vec3 rp,vec4 p){
    
     return dot(rp,normalize(p.xyz))+p.w;  
}

float sdf(vec3 rp){
     
    vec3 p = rp;
    
    p.y += snoise(rp*0.1)*0.5+0.5;
    p.y += snoise(rp*0.01)*5.0+5.0;
    p.y += snoise(rp*0.001)*10.0+5.0;
    
    vec3 cp = rp+vec3(6.0,0,0);
    vec3 cp2 = rp+vec3(6.,3,0);
 
   cp.xz = mod(cp.xz+6.,12.0)-6.;
  cp.y = mod(cp.y+1.,2.0)-1.;
    cp2.xz = mod(cp2.xz+6.,12.0)-6.;
  cp2.y = mod(cp2.y+1.,2.0)-1.;
  // cp.z = sin(cp.z)*2.0+2.0;
    
    float c = sdf_Cylinder(cp,1.0,0.8);
    float c2 = sdf_Cylinder(cp2,1.1,0.2);
    
    return min(c,min(c2,sdf_plane(p,vec4(0,1,0,1))));
}

float RayMarch(vec3 ro , vec3 rd , int MAX_IT , out float steps){
     float z = 0.;
    
    for(int i = 0;i <= MAX_IT;i++){
        steps = float(i);
        if(z > 100.){steps=0.;break;}
        
        vec3 rp = ro + rd * z;
        
        float l = sdf(rp);
        
        
        if(l < 0.001){break;}
        
        z += l;
    }
      steps /= float(MAX_IT);
    return z;
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv -= 0.5;
    uv.x *= resolution.x / resolution.y;
    
    vec3 ro = vec3(0.,5.,-5);
    ro.z += time*10.0;
    
    vec3 mv = ro;
    
    ro.y -= snoise(mv*0.1)*0.5+0.5;
    ro.y -= snoise(mv*0.01)*5.0+5.0;
    ro.y -= snoise(mv*0.001)*10.0+5.0;
    
    vec3 rd = normalize(vec3(uv,1.));
    
    float a = sin(time*2.0)*0.04;
    
    rd.xy *= mat2x2(cos(a),sin(a),-sin(a),cos(a));
    
    float steps = 0.;
    
    float l = RayMarch(ro , rd ,100,steps);

    vec3 rp = ro + rd * l;
    
    float fog = l/100.;
    
    vec3 col = vec3(0.8,0.2,0.)+vec3(1,1,0)*vec3(steps);
    
    col = mix(col , mix(vec3(0.8,0.5,0.2),vec3(0.2,0.2,1.),clamp(rp.y*0.01,0.,1.)), clamp(fog,0.,1.));
    

    glFragColor = vec4(col,1.0);
}

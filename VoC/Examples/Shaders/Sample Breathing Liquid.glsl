#version 420

// original https://www.shadertoy.com/view/mtj3DG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.141592654
#define TWOPI 6.283185308 

vec3 normalMap(vec3 p, vec3 n);
float calcAO( in vec3 pos, in vec3 nor );
float noise_3(in vec3 p); //亂數範圍 [0,1]
vec3 FlameColour(float f);

vec2 SphereMap( vec3 ray){        //ray mapping to UV
   vec2 st;
   ray=normalize(ray);
   float radius=length(ray);
   st.y = acos(ray.y/radius) / PI;
   if (ray.z >= 0.0) st.x = acos(ray.x/(radius * sin(PI*(st.y)))) / TWOPI;
   else st.x = 1.0 - acos(ray.x/(radius * sin(PI*(st.y)))) / TWOPI;
   return st;
}

vec4 warpcolor(in vec2 uv, float t){   //Normalized uv[0~1]
            float strength = 0.4;
        vec3 col = vec3(0);
        //pos coordinates (from -1 to 1)
        vec2 pos = uv*2.0-1.0;
            
        //請小心！QC迴圈最好使用int index，float index有可能錯誤！
        for(int i = 1; i < 6; i++){ 
        pos.x += strength * sin(2.0*t+float(i)*1.5 * pos.y)+t*0.5;
        pos.y += strength * cos(2.0*t+float(i)*1.5 * pos.x);}

        //Time varying pixel colour
        col += 0.5 + 0.5*cos(t+pos.xyx+vec3(0,2,4));
        //Gamma
        col = pow(col, vec3(0.4545));
        return vec4(col,1.0) ;
}

vec3 warpSky(vec3 e){
    vec2 ST = SphereMap(e);
    vec4 color =warpcolor(ST, time*0.1);
    return color.xyz;
}

vec3 phong(vec3 p, vec3 n, vec3 v){
    vec3 final = vec3(0.0);
    vec3 ambient_color=vec3(0.351,0.900,0.955);

    vec2 mouse=(mouse*resolution.xy.xy/resolution.xy)*2.0-1.0;
    {
    vec3 light_pos = vec3(mouse.x,mouse.y,2.0);
    vec3 light_color = vec3(0.245,0.194,0.241);
    vec3 light_vector =normalize(light_pos-p);
    vec3 reflection = normalize(reflect(-light_pos,n));  
    float ka=0.620, ks=1.5, kd= 2.;//各參數權重
    float shineness=5.160;
    
    vec3 diffuse, specular, ambient;
    ambient = ka*ambient_color;
    diffuse= kd*dot(light_vector,n)*light_color;
    specular= ks*pow(max(dot(reflection,v),0.),shineness)*light_color;
    final=ambient_color+diffuse+specular;
    }
    {
  
    vec3 light_pos = vec3(-5.,15.,2.0);
    vec3 light_color = vec3(0.920,0.266,0.258);
    vec3 light_vector =normalize(light_pos-p);
    vec3 reflection = normalize(reflect(-light_pos,n));  
    float ka=0.320, ks=0.8, kd= 0.8;//各參數權重
    float shineness=2.568;
    
    vec3 diffuse, specular, ambient;
    ambient = ka*ambient_color;
    diffuse= kd*dot(light_vector,n)*light_color;
    specular= ks*pow(max(dot(reflection,v),0.),shineness)*light_color;
    final+=(diffuse+specular)*0.6;
    }
    // final+=ambient_color;
    vec3 refl = reflect(-v,n);
    vec3 refl_clr=warpSky(refl);
    float F =1.0-dot(n,v);
    final = mix(final,refl_clr,F);
    return final;
}

//=== distance functions ===
float sdSphere( vec3 p, float s )
{
    return length(p)-s;
}
float sdBox( vec3 p, vec3 b )
{
  vec3 d = abs(p) - b;
  return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}
float sdTorus( vec3 p, vec2 t )
{
  vec2 q = vec2(length(p.xy)-t.x,p.z);
  return length(q)-t.y;
}

float udRoundBox(vec3 p, vec3 b, float r) {
    //p += 0.015 * (noise_3(p*60.0)*2.0-1.0);
    return length(max(abs(p) - b, 0.0)) - r;
}

float map(in vec3 p)
{
float bump=-0.288 * (noise_3(p*3.0)*2.0-1.0);
vec3 p1 = p + bump;

return sdTorus(p1+vec3(sin(time*0.3)*0.2,sin(time)*0.5,0.0),vec2(0.4,0.2));

}

//=== gradient functions ===
vec3 gradient( in vec3 p ) //尚未normalize
{
    const float d = 0.001;
    vec3 grad = vec3(map(p+vec3(d,0,0))-map(p-vec3(d,0,0)),
                     map(p+vec3(0,d,0))-map(p-vec3(0,d,0)),
                     map(p+vec3(0,0,d))-map(p-vec3(0,0,d)));
    return grad;
}

// === raytrace functions===
float trace(vec3 o, vec3 r, out vec3 p)
{
float d=0.0, t=0.0;
for (int i=0; i<15; ++i)
{
    p= o+r*t;
    d=map(p);
    if(d<0.0) break;
    t += d*0.3; //影響輪廓精準程度
    }
return t;
}

//=== sky ===
float fbm(in vec2 uv);
vec3 getSkyFBM(vec3 e) {    //二維雲霧
    vec3 f=e;
    float m = 2.0 * sqrt(f.x*f.x + f.y*f.y + f.z*f.z);
    vec2 st= vec2(-f.x/m + .5, -f.y/m + .5);
    //vec3 ret=texture2D(iChannel0, st).xyz;
    float fog= fbm(0.6*st+vec2(-0.2*time, -0.02*time))*0.5+0.3;
    return vec3(fog);
}

vec3 sky_color(vec3 e) {    //漸層藍天空色
    e.y = max(e.y,0.0);
    vec3 ret;
    //ret.x = pow(1.0-e.y,3.0);
    //ret.y = pow(1.0-e.y, 1.2);
    //ret.z = 0.8+(1.0-e.y)*0.3;
    ret=FlameColour(e.y);
    return ret;
}

vec3 getSkyALL(vec3 e)
{    
    return sky_color(e);
}

//=== camera functions ===
mat3 setCamera( in vec3 ro, in vec3 ta, float cr )
{
    vec3 cw = normalize(ta-ro);
    vec3 cp = vec3(sin(cr), cos(cr),0.0);
    vec3 cu = normalize( cross(cw,cp) );
    vec3 cv = normalize( cross(cu,cw) );
    return mat3( cu, cv, cw );
}

// math
mat3 fromEuler(vec3 ang) {
    vec2 a1 = vec2(sin(ang.x),cos(ang.x));
    vec2 a2 = vec2(sin(ang.y),cos(ang.y));
    vec2 a3 = vec2(sin(ang.z),cos(ang.z));
    vec3 m0 = vec3(a1.y*a3.y+a1.x*a2.x*a3.x,a1.y*a2.x*a3.x+a3.y*a1.x,-a2.y*a3.x);
    vec3 m1 = vec3(-a2.y*a1.x,a1.y*a2.y,a2.x);
    vec3 m2 = vec3(a3.y*a1.x*a2.x+a1.y*a3.x,a1.x*a3.x-a1.y*a3.y*a2.x,a2.y*a3.y);
    return mat3(m0, m1, m2);
}

// ================
void main(void) {
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv = uv*2.0-1.0;
    uv.x*= resolution.x/resolution.y;
    uv.y*=1.0;//校正 預設值uv v軸朝下，轉成v軸朝上相同於y軸朝上為正
    vec2 mouse=(mouse*resolution.xy.xy/resolution.xy)*2.0-1.0;

// camera option1  (模型應在原點，適用於物件)
    vec3 CameraRot=vec3(0.0, mouse.y, mouse.x); 
    vec3 ro= vec3(0.0, 0.0, 2.0)*fromEuler(CameraRot);//CameraPos;
    vec3 ta =vec3(0.0, 0.0, 0.0); //TargetPos; //vec3 ta =float3(CameraDir.x, CameraDir.z, CameraDir.y);//UE座標Z軸在上
    mat3 ca = setCamera( ro, ta, 0.0 );
    vec3 RayDir = ca*normalize(vec3(uv, 2.0));//z值越大，zoom in! 可替換成mouse*resolution.xy.z
    vec3 RayOri = ro;

// camera option2 (攝影機在原點，適用於場景)
/*    
    vec3 CameraRot=vec3(0.0, -mouse*resolution.xy.y, -mouse*resolution.xy.x);
    vec3 RayOri= vec3(0.0, 0.0, 0.0);    //CameraPos;
    vec3 RayDir = normalize(vec3(uv, -1.))*fromEuler(CameraRot);
*/
    
    vec3 p,n;
    float t = trace(RayOri, RayDir, p);
    n=normalize(gradient(p));
    vec3 bump=normalMap(p*1.652,n);
    n=n+bump*0.05;
    
    float edge= dot(-RayDir, n);
    //edge = step(0.2, edge);
    edge = smoothstep(-0.072, 0.956, edge);
    
    
        
//SHADING
    vec3 result=n;
    vec3 ao = vec3(calcAO(p,n));
    //result = vec3(edge);
    result= phong(p,n,-RayDir)*ao;  //攝影機觀看視角(V)要轉負的，因為是方向是從物體發出到攝影機  //需要外接的話燈光另外寫
    //result*=(1.-edge);
//HDR環境貼圖
    vec3 refl = reflect(RayDir,n);
    vec3 refl_clr=warpSky(refl);
    //vec3 BG=vec3(0.99);       
    vec3 BG=refl_clr;

if(t<2.5) glFragColor = vec4(vec3(result),1.0); else glFragColor = vec4(BG,1.0);//測試n, n_bump, fresnel, BG, color, fog, F, I, SS, reflectedCol
}

//=== 3d noise functions ===
float hash11(float p) {
    return fract(sin(p * 727.1)*43758.5453123);
}
float hash12(vec2 p) {
    float h = dot(p,vec2(127.1,311.7));    
    return fract(sin(h)*43758.5453123);
}
vec3 hash31(float p) {
    vec3 h = vec3(1275.231,4461.7,7182.423) * p;    
    return fract(sin(h)*43758.543123);
}

// 3d noise
float noise_3(in vec3 p) {
    vec3 i = floor(p);
    vec3 f = fract(p);    
    vec3 u = f*f*(3.0-2.0*f);
    
    vec2 ii = i.xy + i.z * vec2(5.0);
    float a = hash12( ii + vec2(0.0,0.0) );
    float b = hash12( ii + vec2(1.0,0.0) );    
    float c = hash12( ii + vec2(0.0,1.0) );
    float d = hash12( ii + vec2(1.0,1.0) ); 
    float v1 = mix(mix(a,b,u.x), mix(c,d,u.x), u.y);
    
    ii += vec2(5.0);
    a = hash12( ii + vec2(0.0,0.0) );
    b = hash12( ii + vec2(1.0,0.0) );    
    c = hash12( ii + vec2(0.0,1.0) );
    d = hash12( ii + vec2(1.0,1.0) );
    float v2 = mix(mix(a,b,u.x), mix(c,d,u.x), u.y);
        
    return max(mix(v1,v2,u.z),0.0);
}
//=== glow functions ===
float glow(float d, float str, float thickness){
    return thickness / pow(d, str);
}

//=== 2d noise functions ===
vec2 hash2( vec2 x )            //亂數範圍 [-1,1]
{
    const vec2 k = vec2( 0.3183099, 0.3678794 );
    x = x*k + k.yx;
    return -1.0 + 2.0*fract( 16.0 * k*fract( x.x*x.y*(x.x+x.y)) );
}
float gnoise( in vec2 p )        //亂數範圍 [-1,1]
{
    vec2 i = floor( p );
    vec2 f = fract( p );
    
    vec2 u = f*f*(3.0-2.0*f);

    return mix( mix( dot( hash2( i + vec2(0.0,0.0) ), f - vec2(0.0,0.0) ), 
                             dot( hash2( i + vec2(1.0,0.0) ), f - vec2(1.0,0.0) ), u.x),
                         mix( dot( hash2( i + vec2(0.0,1.0) ), f - vec2(0.0,1.0) ), 
                             dot( hash2( i + vec2(1.0,1.0) ), f - vec2(1.0,1.0) ), u.x), u.y);
}
float fbm(in vec2 uv)        //亂數範圍 [-1,1]
{
    float f;                //fbm - fractal noise (4 octaves)
    mat2 m = mat2( 1.6,  1.2, -1.2,  1.6 );
    f   = 0.5000*gnoise( uv ); uv = m*uv;          
    f += 0.2500*gnoise( uv ); uv = m*uv;
    f += 0.1250*gnoise( uv ); uv = m*uv;
    f += 0.0625*gnoise( uv ); uv = m*uv;
    return f;
}

//=== 3d noise functions p/n ===
vec3 smoothSampling2(vec2 uv)
{
    const float T_RES = 32.0;
    return vec3(gnoise(uv*T_RES)); //讀取亂數函式
}

float triplanarSampling(vec3 p, vec3 n)
{
    float fTotal = abs(n.x)+abs(n.y)+abs(n.z);
    return  (abs(n.x)*smoothSampling2(p.yz).x
            +abs(n.y)*smoothSampling2(p.xz).x
            +abs(n.z)*smoothSampling2(p.xy).x)/fTotal;
}

const mat2 m2 = mat2(0.90,0.44,-0.44,0.90);
float triplanarNoise(vec3 p, vec3 n)
{
    const float BUMP_MAP_UV_SCALE = 0.2;
    float fTotal = abs(n.x)+abs(n.y)+abs(n.z);
    float f1 = triplanarSampling(p*BUMP_MAP_UV_SCALE,n);
    p.xy = m2*p.xy;
    p.xz = m2*p.xz;
    p *= 2.1;
    float f2 = triplanarSampling(p*BUMP_MAP_UV_SCALE,n);
    p.yx = m2*p.yx;
    p.yz = m2*p.yz;
    p *= 2.3;
    float f3 = triplanarSampling(p*BUMP_MAP_UV_SCALE,n);
    return f1+0.5*f2+0.25*f3;
}

vec3 normalMap(vec3 p, vec3 n)
{
    float d = 0.005;
    float po = triplanarNoise(p,n);
    float px = triplanarNoise(p+vec3(d,0,0),n);
    float py = triplanarNoise(p+vec3(0,d,0),n);
    float pz = triplanarNoise(p+vec3(0,0,d),n);
    return normalize(vec3((px-po)/d,
                          (py-po)/d,
                          (pz-po)/d));
}

//=== iq’s calc AO ===
float calcAO( in vec3 pos, in vec3 nor )
{
    float ao = 0.0;

    vec3 v = normalize(vec3(0.7,-0.1,0.1));
    for( int i=0; i<12; i++ )
    {
        float h = abs(sin(float(i)));
        vec3 kv = v + 2.0*nor*max(0.0,-dot(nor,v));
        ao += clamp( map(pos+nor*0.01+kv*h*0.08)*3.0, 0.0, 1.0 );
        v = v.yzx; //if( (i&2)==2) v.yz *= -1.0;
    }
    ao /= 12.0;
    ao = ao + 2.0*ao*ao;
    return clamp( ao*5.0, 0.0, 1.0 );
}

//=== flame color ===
//thanks iq..
// Smooth HSV to RGB conversion 
vec3 hsv2rgb_smooth( in vec3 c )
{
    vec3 rgb = clamp( abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),6.0)-3.0)-1.0, 0.0, 1.0 );

    rgb = rgb*rgb*(3.0-2.0*rgb); // cubic smoothing    

    return c.z * mix( vec3(1.0), rgb, c.y);
}

vec3 hsv2rgb_trigonometric( in vec3 c )
{
    vec3 rgb = 0.5 + 0.5*cos((c.x*6.0+vec3(0.0,4.0,2.0))*3.14159/3.0);

    return c.z * mix( vec3(1.0), rgb, c.y);
}

vec3 FlameColour(float f)
{
    return hsv2rgb_smooth(vec3((f-(2.25/6.))*(1.25/6.),f*1.25+.2,f*.95));
}

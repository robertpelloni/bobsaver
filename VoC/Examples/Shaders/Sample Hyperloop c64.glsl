#version 420

// original https://www.shadertoy.com/view/ddBSWK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define chillTime time/90.
// best between 60 and 140 seconds

#define C64_COLOR 0
#define AMIGA_COLOR 1

//-------------------------------------------------------------------
//--------------------------Effects----------------------------------
//-------------------------------------------------------------------

float tri(in float x){return abs(fract(x)-0.5);}

//from iq
vec3 hsl2rgb(in vec3 c){
    vec3 rgb = clamp( abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),6.0)-3.0)-1.0, 0.0, 1.0 );

    return c.z + c.y * (rgb-0.5)*(1.0-abs(2.0*c.z-1.0));
}

vec3 hsv2rgb(in vec3 c){
    vec3 rgb = clamp( abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),6.0)-3.0)-1.0, 0.0, 1.0 );
    
    return c.z * mix( vec3(1.0), rgb, c.y);
}

vec3 fx1(in vec2 p)
{
    return hsl2rgb(clamp(vec3(p.x,p.y,p.y),0.,1.));
}

//-------------------------------------------------------------------
//---------------------------RGB to C64------------------------------
//-------------------------------------------------------------------

vec3 pal[16];  //Palette from: http://www.pepto.de/projects/colorvic/
void setpal()
{
    pal[0]=vec3(0),pal[1]=vec3(1),pal[2]=vec3(0.4530,0.2611,0.2089),pal[3]=vec3(0.4845,0.6764,0.7286), pal[4]=vec3(0.4825,0.2829,0.5663),pal[5]=vec3(0.3925,0.5921,0.3087),
    pal[6]=vec3(0.2500,0.1972,0.5206), pal[7]=vec3(0.7500,0.8028,0.4794),pal[8]=vec3(0.4825,0.3576,0.1837),pal[9]=vec3(0.3082,0.2691,0.0000),pal[10]=vec3(0.6405,0.4486,0.3964),
    pal[11]=vec3(0.3125,0.3125,0.3125),pal[12]=vec3(0.4688,0.4688,0.4688),pal[13]=vec3(0.6425,0.8421,0.5587),pal[14]=vec3(0.4688,0.4159,0.7393),pal[15]=vec3(0.6250,0.6250,0.6250);
}

float rectify(in float f){ return mix(pow(((f + 0.055)/1.055), 2.4), f / 12.92, step(f, 0.04045))*100.; }
float pivot(in float x){ return mix(pow(x,0.3333), (903.3*x + 16.)/116., step(x,216.0/24389.0)); }
//RGB to Lab (for color differencing) https://github.com/THEjoezack/ColorMine
vec3 rgb2lab(in vec3 c)
{
    c.r = rectify(c.r);
    c.g = rectify(c.g);
    c.b = rectify(c.b);
    c  *= mat3( 0.4124, 0.3576, 0.1805,
                  0.2126, 0.7152, 0.0722,
                0.0193, 0.1192, 0.9505);
    vec3 w = normalize(vec3(1.3,1.33,1.1));
    c.x = pivot(c.x/w.x);
    c.y = pivot(c.y/w.y);
    c.z = pivot(c.z/w.z);
    
    return vec3(max(0.,116.*c.y-16.), 500.*(c.x-c.y), 200.*(c.y-c.z));
}

float hash(in float n){return fract(sin(n)*43758.5453);}
//Using CIE76 for color difference, mainly because it is much cheaper
vec3 c64(in vec3 c, in vec2 p)
{
    c = clamp(c,.0,1.);
    
    vec3 hsv = rgb2lab(c);
    float d = 100000.;
    float d2 = 100000.;
    vec3 c2 = vec3(0);
    for(int i=0;i<16;i++)
    {
        vec3 ch = rgb2lab(pal[i]);
        float cd = distance(hsv,ch);
        if (cd < d)
        {
            d2 = d;
            c2 = c;
            d = cd;
            c = pal[i];
        }
        else if(cd < d2)
        {
            d2 = cd;
            c2 = pal[i];
        }
    }
    
    const float sclx = 320.;
    const float scly = 200.;
    float id = floor(p.x*sclx)*1.1+floor(p.y*scly)*2.;
    float px = mod(floor(p.x*sclx)+floor(p.y*scly),2.);
#ifdef AUTO_DITHER
    float rn = hash(id);
    if (rn < smoothstep(d2*0.96, d2*1., d*1.01) && (px ==0.))c=c2;
#endif
    return pow(abs(c),vec3(1.136));  //correct gamma
}

float inverseLerp(float v, float minValue, float maxValue) {
  return (v - minValue) / (maxValue - minValue);
}

float remap(float v, float inMin, float inMax, float outMin, float outMax) {
  float t = inverseLerp(v, inMin, inMax);
  return mix(outMin, outMax, t);
}

vec3 vignette(vec2 uv) {
  float distFromCenter = length(abs(uv));

  float vignette = 1.0 - distFromCenter;
  vignette = smoothstep(0.0, 0.7, vignette);
  vignette = remap(vignette, 0.0, 1.0, 0.3, 1.0);

  return vec3(vignette);

}

vec3 rgb2hsv(vec3 c)
{
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}
/*
vec3 hsv2rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}*/
float noise(vec2 st){
    return fract(sin(dot(vec2(12.23,74.343),st))*43254.);  
}

#define pi acos(-1.)
float noise2D(vec2 st){
  
  //id,fract
  vec2 id =floor(st);
  vec2 f = fract(st);
  
  //nachbarn
  float a = noise(id);
  float b = noise(id + vec2(1.,0.));
  float c = noise(id + vec2(0.,1.));
  float d = noise(id + vec2(1.));
  
  
  //f
  f = smoothstep(0.,1.,f);
  
  //mix
  float ab = mix(a,b,f.x);
  float cd = mix(c,d,f.x);
  return mix(ab,cd,f.y);
}

mat2 rot45 = mat2(0.707,-0.707,0.707,0.707);

mat2 rot(float a){
  float s = sin(a); float c = cos(a);
  return mat2(c,-s,s,c);
}
float fbm(vec2 st, float N, float rt,float time){
    st*=3.;
 
  float s = .5;
  float ret = 0.;
  for(float i = 0.; i < N; i++){
     
      ret += noise2D(st)*s; st *= 2.9; s/=2.; st *= rot((pi*(i+1.)/N)+rt*8.);
      st.x += time/10.;
  }
  return ret;
 
}

void main(void) {
    setpal();
    //C64 native resolution (320x200)
    vec2 p = gl_FragCoord.xy / resolution.xy;
    vec2 bp = p;
    
    float time = remap(sin(chillTime)*3.*cos(chillTime),-1.,1.,10., 70.);
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv2 = gl_FragCoord.xy/resolution.xy;

    vec2 position = - 1.0 + 2.0 * uv2;
    position.x +=sin(time)*0.5;

    
    //space odyssey final scene
    //position*=sin(time)/30.*0.5+0.5 * 30.;
    
    float a = atan( position.y, position.x );
    float r = sqrt( dot( position, position ) );

    vec2 uv;
    uv.x = cos( a ) / r;
    uv.y = sin( a ) / r;
    uv /= 5.0;
    uv += time/4. ;
    
    /*vec2 uv;
    uv.x = cos( a ) / r;
    uv.y = sin( a ) / r;
    uv /= 1.025+sin(time/6.)/6.;
    uv*=6.5;*/
    //uv += time/30.;
    
    // fbm it
    uv*=rot(sin(fbm(uv,10.,sin(time/4000.),time)));
    
    // more granularity
    uv=uv*rot(time/4.);    
    
    float red = abs( sin( uv.x * uv.y + time / 5.0) );
    float green = abs( sin( uv.x * uv.y + time / 4.0 ) );
    float blue = abs( sin( uv.x * uv.y + time /3.0) );
    glFragColor = vec4( red, green, blue, 1.0 );
    
    // trip clouds
    glFragColor.xyz = 0.5 + 0.5*cos(time+uv.xyx+vec3(0,2,4));
    //clamp(0.5,0.0,1.0);
    float factor = cos(uv.x+uv.y/4.)*0.5+0.5;

    glFragColor.xyz = mix(0.5 + 0.5*cos(time+uv.xyx+vec3(0,2,4)),glFragColor.xyz, factor);
    //vec3 result = clamp(texCol0.rgb - Density*(texCol1.rgb), 0.0, 1.0);
    // flashes?
    
    vec3 hsvCol = rgb2hsv(glFragColor.xyz);
    //hsvCol.r = (sin(time/3.)*0.5+0.5);
    #if AMIGA_COLOR == 1
    hsvCol.g += 0.618; // saturation
    hsvCol.b -= .1; // brightness
    #endif

    #if C64_COLOR == 1
    hsvCol.g -= 0.5; // saturation
    hsvCol.b += .1; // brightness

    #endif
    glFragColor.xyz= hsv2rgb(hsvCol);
    
    
    #if AMIGA_COLOR == 1
    // Simulate Amiga's color palette containing no less than 4096 colors (RGB444)
    glFragColor.r = ceil(glFragColor.r * 255.0 / 16.0) * 16.0 / 256.0;
    glFragColor.g = ceil(glFragColor.g * 255.0 / 16.0) * 16.0 / 256.0;
    glFragColor.b = ceil(glFragColor.b * 255.0 / 16.0) * 16.0 / 256.0;
    #endif
    
    #if C64_COLOR == 1
    //vec2 p = gl_FragCoord.xy / resolution.xy;
    vec3 col = fx1(uv); 
    //vec2 bp = p;
    glFragColor.xyz = c64(glFragColor.xyz,uv);
    #endif
    
    // create a circle mask
    //vec3 mask = vignette(uv*0.5);

    // apply the mask to the fragment color
    //glFragColor.xyz+=vec3(mask);
    //gl_FragColor = vec4(vec3(mask), 1.0);
    
    

}

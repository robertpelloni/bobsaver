#version 420

// original https://www.shadertoy.com/view/XtXBD7

uniform float time;
uniform vec2 resolution;

out vec4 glFragColor;

#define ATMOSPHEREHEIGHT 2400
#define time -time/20.0+0.5
#define FOV 0.5
#define AURORORHEIGHT 100.0
#define AURORORBRIGHTNESS 1.5

vec3 cam = vec3(0,10.0,0);

#define sunpos vec3(0,sin(time),cos(time))
vec3 CENTER = vec3(0.0,-63710.0,0.0);
float dts( vec3 camm,vec3 poss,vec3 center, float radius,float sig){
float a =
       pow((dot(normalize(poss-camm),camm-center)),2.0)
       -pow(length(camm-center),2.0)+pow(radius,2.0);
if (a<0.0){return -1.0;}
float dd = -(dot(normalize(poss-camm),(camm-center)))
       +sig*sqrt(a);
//if (dd < 0.0){return -1.0;}
return dd;

}

float random (in vec3 _st) {
    return fract(sin(dot(_st.xyz,
                         vec3(12.9898,78.233,82.19)))*
        43758.5453123);
}

float starnoise (in vec3 _st) {
    vec3 i = floor(_st);
    vec3 f = fract(_st);

    // Four corners in 2D of a tile
    float starthreshhold = 0.99;
    float a = float(random(i)>starthreshhold);
    float b = float(random(i + vec3(1.0, 0.0,0.0))>starthreshhold);
    float c = float(random(i + vec3(0.0, 1.0,0.0))>starthreshhold);
    float d = float(random(i + vec3(1.0, 1.0,0.0))>starthreshhold);

    float e = float(random(i + vec3(0.0, 0.0,1.0))>starthreshhold);
    float g = float(random(i + vec3(1.0, 0.0,1.0))>starthreshhold);
    float h = float(random(i + vec3(0.0, 1.0,1.0))>starthreshhold);
    float j = float(random(i + vec3(1.0, 1.0,1.0))>starthreshhold);

    f = (1.0-cos(f*3.1415))/2.0;
   // f = 0.5+sign(f-0.5)*0.5*pow(abs(f-0.5)*2.0,vec3(3.0));
   // float a1 = mix(a, b, u.x) +
     //       (c - a)* u.y * (1.0 - u.x) +
     //(d - b) * u.x * u.y;
     float a1 = mix(a,b,f.x);
     float a2 = mix(c,d,f.x);
     float a3 = mix(e,g,f.x);
     float a4 = mix(h,j,f.x);

     float a5 = mix(a1,a2,f.y);
     float a6 = mix(a3,a4,f.y);

    return mix(a5,a6,f.z);
}

float noise (in vec3 _st) {
    vec3 i = floor(_st);
    vec3 f = fract(_st);

    // Four corners in 2D of a tile
    float a = random(i);
    float b = random(i + vec3(1.0, 0.0,0.0));
    float c = random(i + vec3(0.0, 1.0,0.0));
    float d = random(i + vec3(1.0, 1.0,0.0));

    float e = random(i + vec3(0.0, 0.0,1.0));
    float g = random(i + vec3(1.0, 0.0,1.0));
    float h = random(i + vec3(0.0, 1.0,1.0));
    float j = random(i + vec3(1.0, 1.0,1.0));

    f = (1.0-cos(f*3.1415))/2.0;
   // float a1 = mix(a, b, u.x) +
     //       (c - a)* u.y * (1.0 - u.x) +
     //(d - b) * u.x * u.y;
     float a1 = mix(a,b,f.x);
     float a2 = mix(c,d,f.x);
     float a3 = mix(e,g,f.x);
     float a4 = mix(h,j,f.x);

     float a5 = mix(a1,a2,f.y);
     float a6 = mix(a3,a4,f.y);

    return mix(a5,a6,f.z);
}

float fbm ( in vec3 _st) {
    float v = 0.0;
    float a = 0.5;
    vec3 shift = vec3(100.0,22.5,44.0);
    float r = 1.0;
    for (int i = 0; i < 4; ++i){
        v += a * noise(_st);
        r += a;
        _st =  shift + _st*2.0;
        _st = (sin(r)*_st+cos(r)*_st);
        a *= 0.5;
    }
    return v;
}
float edis(vec3 from,vec3 to){
vec3 plac = CENTER;
float rad = -CENTER.y - 6.0;

float a = dts(from,to,plac,rad,-1.0);
float b = dts(from,to,plac,rad, 1.0);

if(a<0.0&&b<0.0)
{
return -1.0;
}
if(a < 0.0){return b;}
if(b < 0.0){return a;}

return min(a,b);

}
float sdis(vec3 from,vec3 to){
vec3 plac = CENTER;
float rad = -CENTER.y + float(ATMOSPHEREHEIGHT);

float a = dts(from,to,plac,rad,-1.0);
float b = dts(from,to,plac,rad, 1.0);

if(a<0.0&&b<0.0)
{
return -1.0;
}
if(a < 0.0){return b;}
if(b < 0.0){return a;}

return min(a,b);
}
vec3 outscatter(float r){

vec3 a =  vec3(1.02651);
vec3 b = vec3(620.0,540.0,460.0)*1.0;
vec3 os = (2.0*3.1415*4079.660796735571*a*a*r)/(b*b*b*b);
return 1.0 - os;

}
vec3 scatter(float intensity,vec3 lightdir,vec3 from, vec3 to){

vec3 l = lightdir;
float d = intensity;

float r = distance(from,to);
float c = acos(dot(normalize(to-from),normalize(l)));
vec3 a =  vec3(1.02651);
vec3 b = vec3(620.0,540.0,460.0)*1.0;

float si = sdis(mix(to,from,0.5)+l*0.5, mix(to,from,0.5)+l);
float ai = sdis(mix(to,from,0.99)+l*0.5, mix(to,from,0.99)+l);;
float fi = 0.5*(si+ai);
//float si = edis(from-l*0.5, from+l);
//if(si<ai){return vec3(0.0);};
float mol = 215443.469003;
float area = sin(c)*r*(si+ai)*0.5;
vec3 is = d * 100.0*r * (779.180801368*a*a*(1.5+0.5*cos(2.0*c))/(pow(b,vec3(4.0))));

//vec3 os = 2.0*25214649.0*a*a*d*8.0*pow(3.1415,5.0)*r/(16053091.0*b*b*b*b);
return (is*outscatter(((si+ai)/2.0)*300.0));//(0.5*(r+distance(from+l*si,pos+l*fi)))) ;

}
float getcloud(in vec3 a)
{
    float r = fbm( a / 20.0 + vec3(time*3.0, time*2.0, 0.0) );
       float th = 0.55;//sin(210.11);
return max(1.0-r/th,0.0);
}
vec3 getwatnorm(in vec3 a)
{
vec3 waveoffset = vec3(0.0, 0.0, time*5.0);
vec3 dn = normalize(a-CENTER)*0.12;//*fbm(waveoffset.yzx*2.0+a/10.0);
vec3 d = vec3(0.01, 0.01, 0.0);
return normalize(cross(a+d.xzz+dn*fbm(waveoffset +a+d.xzz)-a-dn*fbm(waveoffset +a),a+d.zzx+dn*fbm(waveoffset +a+d.zzx)-a-dn*fbm(waveoffset +a)));

}
float afbm(in vec3 a){

return fbm(a)*max(1.0-a.y,0.0);
}
vec3 getaurora(in vec3 a){
    float av = AURORORHEIGHT;//200.0;
    vec3 acc = vec3(0.0);
    for(float i = 0.0;i < av;i++){
        vec3 z = a;
        z.xz = z.xz/((float(i)/(50.0))+1.0) ;
float r = fbm(z/800.0+vec3(0.0,time,0.0));
    float th = sin(210.11);
       acc+=float(r>th&&r<(th+0.05*sin(distance(a.xz,cam.xz)/5000.0)))*vec3(0.0025*pow(max(1.0-abs(i/av),0.0),2.0),0.025*pow(abs(i/av-0.5)*2.0,1.0),0.0125*pow((i/av),1.0/2.0)).xzy*AURORORBRIGHTNESS*i/av;
    }

    return acc;
}
void main(void)
{
    //cam.y=fbm(cam+vec3(0.0,0.0,time*5.0))*10.0;
    vec2 uv = gl_FragCoord.xy / resolution.xy-0.5;
    
    vec2 mouse=vec2(0.0);
    vec2 look = (mouse*resolution.xy.xy-mouse*resolution.xy)/resolution.xy*3.1415*2.0+3.1415;
    look=mix(vec2(3.1415),look,0.0);
    look.y=look.y*0.5+3.1415/2.0+3.1415;
    look.x = -look.x + 3.1415;
    
    //xy = mouse when clickdown
    //zw = mouse when clickfirst
    vec3 screen = vec3(0.0);//
    screen.x = uv.x;
    screen.y = -sin(look.y)*FOV+cos(look.y)*uv.y*(resolution.y/resolution.x);
    screen.z = cos(look.y)*FOV+sin(look.y)*uv.y*(resolution.y/resolution.x);
   float temp = screen.x;
    screen.x = cos(look.x)*screen.x+sin(look.x)*screen.z;
    
    screen.z = -sin(look.x)*temp+cos(look.x)*screen.z;
    
    
   
    vec3 pos = cam+screen;
vec3 virtualPos = pos;
vec3 directionToFragmentPosition = normalize(pos-cam);
vec3 lightDir = sunpos;
float distanceToGround = edis(cam,pos);
    vec3 groundPosition = cam+directionToFragmentPosition*distanceToGround;
float preReflectionDistance = 0.0;
    vec3 preReflectionDirection = vec3(0.1);
   if(distanceToGround>0.0){
       preReflectionDistance = distanceToGround;
       cam = groundPosition;
       preReflectionDirection = directionToFragmentPosition;
       directionToFragmentPosition = reflect(directionToFragmentPosition,getwatnorm(groundPosition/10.0));
       
       //  fragmentColor = scatter(50.0,-lightDir,cam,groundPosition)*-dot(groundDirection,lightDir)*vec3(getcloud(groundPosition+vec3(10.1)),getcloud(groundPosition),getcloud(-groundPosition));
     //max(outscatter((distance(cam,groundPosition))*30.0),vec3(0.0))*scatter(50.0,lightDir,cam,groundPosition)*mix(vec3(0.40,0.20,0.2),vec3(0.45,0.33,0.2),getcloud(groundPosition))*-dot(normalize(groundPosition-CENTER),lightDir);
    }
    
   float distanceToSky = sdis(cam,cam+directionToFragmentPosition);
    vec3 skyPosition = cam+directionToFragmentPosition*distanceToSky;
   
    virtualPos = skyPosition;
    vec3 skyColor = scatter(50.0,lightDir,cam,virtualPos)+scatter(50.0,lightDir,vec3(0.0),preReflectionDirection)*preReflectionDistance;
    //if(distance(cam,CENTER)>CENTER.y){distanceToSky = distanceToGround - distanceToSky;}

    float sunColor = pow(max(dot(directionToFragmentPosition,vec3(lightDir)),0.0),200.0);
    skyColor += 2.0 * sunColor * max(outscatter(150.0 * (distance(cam, virtualPos)+preReflectionDistance)),0.0);
    vec3 skyDirection = normalize(virtualPos - CENTER);
    vec2 cloudColor =  vec2(( pow(getcloud(skyPosition/50.0),3.0)),( pow(getcloud(skyPosition/50.0+lightDir*3.0*vec3(0.0,0.0,1.0)),2.0))) ;
 vec3 groundDirection = normalize(groundPosition - CENTER);
    vec2 skyPolarCoords = vec2(atan(skyDirection.y,skyDirection.z),asin(skyDirection.x)+3.1415/2.0);
    float star = (starnoise(virtualPos/30.0));
    vec3 starCol = vec3(pow(star,1.0));
    starCol += getaurora(virtualPos);
    float a = sdis(virtualPos+lightDir*0.5,virtualPos+lightDir);
    float b = edis(virtualPos+lightDir*0.5,virtualPos+lightDir);
    float distanceToNight = float(a>b)*a;
    skyColor *= max(outscatter((distanceToNight)*300.0),vec3(0.0));
    skyColor = mix(skyColor,vec3(1.0),cloudColor.x*1.0);
    skyColor = mix(skyColor,vec3(0.9),cloudColor.y*1.0);
    vec3 fragmentColor = mix(clamp(skyColor,vec3(0.0),vec3(1.0)),starCol,1.0-max(outscatter((distanceToNight)*300.0),vec3(0.0)));
  //  if(distanceToGround>0.0){
  //  fragmentColor = scatter(50.0,-lightDir,cam,groundPosition)*-dot(groundDirection,lightDir)*vec3(getcloud(groundPosition+vec3(10.1)),getcloud(groundPosition),getcloud(-groundPosition));
     //max(outscatter((distance(cam,groundPosition))*30.0),vec3(0.0))*scatter(50.0,lightDir,cam,groundPosition)*mix(vec3(0.40,0.20,0.2),vec3(0.45,0.33,0.2),getcloud(groundPosition))*-dot(normalize(groundPosition-CENTER),lightDir);
  //  }
 glFragColor = vec4(fragmentColor,1.0);
}

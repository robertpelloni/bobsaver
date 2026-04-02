#version 420

// original https://www.shadertoy.com/view/3sB3zd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec4 c0 = vec4(0.15,0.35,0.56,1.);//BG
vec4 c1 = vec4(1.00,0.65,0.40,1.);//

float R;
const int samples = 20;
vec2 g;
vec2 uv;
vec4 color;

const float PI = 3.14159265;

struct Square{
    float size;
    vec2 pos;
    vec2 vel;
};
  float wave(float x , float f, float a){
    return  cos(x*f)*a ;
}
    
 Square SquareCons(vec2 pos,float size){
        Square sq;
        sq.pos = pos;
        sq.size = size;
        return sq;
}
    
 float cLength(vec2 p){
  if(abs(p.x)>abs(p.y))return abs(p.x);
  return abs(p.y);
}    

float r = 0.03;
vec4 drawCircle(vec2 v){ 
        float d = length(uv-v);
        if( d < r)return vec4(0);
        return vec4(d);
}

float track(float x){
    float f = 0.;
    //float po = sin(time);
    //float yo = tan(time*1.0);
     float t = 0.03 * (-time*130.0);
   
    x *= 40.;
    f+=cos(x)*1. ;
    
    f += 10.* 
        sin(x*2.1 + t) * .55
      *sin(x*1.72 + t * 1.121) * .50
     //sin(x*2.221 + t * 0.437) * .50;
     * sin(x*3.1122+ t * 4.269) * 0.35;
    return f;
}

float disp(vec2 p){
    return -0.01*sin(p.y*10.+time*10.);
}

vec4 drawSquare(Square sq,vec2 v){

       vec2 p = uv-sq.pos;
       vec2 q = p;
    
    v *= smoothstep(0.,1.,length(v)*10.);
    v = -v;
   
    
    float unko = dot(p,normalize(v));

    float po = length(v)  - unko ;
    po = min(po,unko);
    //po += 0.08 * sin(unko*200.);
    
    

      vec2 vertV = vec2(v.y , -v.x);
      float Pvx = dot(q,normalize(vertV));//
       //Pvx += length(q);
    
      float vl = length(v);
    
       float d2 = disp(vec2(Pvx,unko));
       vl  *=0.6+ (
           track(Pvx)
           );
       if(unko>0.5*vl) vl *=1.+d2*30.;
    

      unko = clamp(unko,0.,vl);
      q  -= normalize(v) * unko;
      

         float d1 =   length(q);
        float d = d1;
        //if( d < sq.size)return vec4(0);
        return vec4(d);
}

vec2 res(float t){
    vec2 p = vec2(0);
    float r = 0.85;
   
    t *= 0.5;
    p.x = r * (smoothstep(-1.,1., sin(t*7.)) -0.5);
    p.y = 0.0 * (smoothstep(-1.,1., cos(t*0.1)) -0.5);

    return p;
}

void main(void)
{
    uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.x;
    color = vec4(1);
    vec2 mouseUV = (mouse*resolution.xy.xy-.5*resolution.xy)/resolution.x; 
    
    mouseUV = res(time);
  //  mouseUV = vec2(0);

    
    vec2 prevPos = res(time-0.05); 
   
    vec2 v = res(time)-prevPos;
    
    Square sq = SquareCons(mouseUV,0.03);    

    vec4 t  = drawSquare(sq,v); 
     t = vec4(smoothstep(0.,1.,t));
    
    
     //t = min(t,drawCircle(normalize(v)*.25));
     t = vec4(step(0.005,t)); 
     if(t.x==0.)color = c1;
    else color = c0;
    glFragColor = color;
}

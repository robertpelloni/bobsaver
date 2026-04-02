#version 420

// original https://www.shadertoy.com/view/wtfcWN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAX_STEPS 100
#define MAX_DIST 100.
#define SURF_DIST .01
#define MAX_ITER 5

float sdRoundBox( vec3 p, vec3 b, float r )
{
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0) - r;
}

float sdBox( vec3 p, vec3 b )
{
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float sdSphere(vec3 p, float r){
    
    return length(p)-r;
}

vec3 rotateY(vec3 p, float alpha){
    float px=p.x;
    float c=cos(alpha);
    float s=sin(alpha);
    
     p.x=c*px-s*p.z;
    p.z=s*px+c*p.z;
    
    return p;
}

vec3 rotateX(vec3 p, float alpha){
    float py=p.y;
    float c=cos(alpha);
    float s=sin(alpha);
    
     p.y=c*py-s*p.z;
    p.z=s*py+c*p.z;
    
    return p;
}

float sdMenger(vec3 p){
    float size=2.;
    p.z -=3.;  
    p=rotateY(p,time*.5);
    vec3[] s = vec3[](vec3(1,1,1),vec3(1,1,0));
    
    for(int iter=0;iter<MAX_ITER;++iter){
    //    float d=MAX_DIST;
        float alpha=0.0;//(mouse*resolution.xy.x-.5*resolution.x)/resolution.x*3.14; 
        p=rotateY(p,alpha);
        float beta=0.00;//(mouse*resolution.xy.y-.5*resolution.y)/resolution.y*3.14; 
        p=rotateX(p,beta);
       // vec3 pos=vec3(0.,0.,0.);
       
        p=abs(p);
        if(p.y > p.x) p.yx = p.xy;
        if(p.z > p.y) p.zy = p.yz;
        
       /* for(int k=0;k<2;k++){
            float dist = length(p-size*s[k]);
            if(dist < d){                
                pos=size*s[k];  
                d=dist;
            }
        
        
        }  
        
        p -= pos;*/
        
        if(p.z > .5*size) p -= size*s[0];
        else p -= size*s[1];
        size /=3.;
        
    }
    return sdBox(p,vec3(1.5*size));
}

float sdPlane(vec3 p,vec3 n){
    n=normalize(n);
     return dot(p,n);   
}
 

float GetDist(vec3 p){
    float d2=sdPlane(p+vec3(0,6,0),vec3(0,1,0));  
    float d1=sdMenger(p);
    
    return min(d1,d2);
}

vec3 GetColor(vec3 p){
 float d1=sdMenger(p);
 float d2=sdPlane(p+vec3(0,6,0),vec3(0,1,0));  
 
    if (d1 < d2) return vec3(1,1,1);;
    
    vec3 col=vec3(.7,.7,.9);
    if((mod(p.x,10.) > 5. && mod(p.z,10.) > 5.)||(mod(p.x,10.) < 5. && mod(p.z,10.) < 5.)) 
        col=vec3(.5);
    
    return col;
    
}

float RayMarch(vec3 ro,vec3 rd){
    float dO=0.;
    
    for(int i=0; i<MAX_STEPS; i++){
     vec3 p=ro+rd*dO;
        float dS=GetDist(p);
        dO +=dS;
        if(dO > MAX_DIST || dS< SURF_DIST) break;        
    
    }
    return dO;
}
    
vec3 GetNormal(vec3 p){
    float d=GetDist(p);
    vec2 e=vec2(.01,0);
    
    vec3 n= d-vec3(
        GetDist(p-e.xyy),
        GetDist(p-e.yxy),
        GetDist(p-e.yyx));
        
    return normalize(n);
}

float shadow( in vec3 ro, in vec3 rd, float mint, float maxt, float k )
{
    float res = 1.0;
    for( float t=mint; t<maxt; )
    {
        float h = GetDist(ro + rd*t);
        if( h<0.001 )
            return 0.0;
        res = min( res, k*h/t );
        t += h;
    }
    return res;
}

void main(void)
{
    vec3 ro = vec3(0,5,-12);
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    vec3 cubecol = vec3(1.,.0,.0);  
    vec3 rd = normalize(vec3(uv.x, uv.y-.5,1)); 
    
    
    float d=RayMarch(ro,rd);   
    vec3 p= ro+rd*d;   
   
    //Get Light
    vec3 lightPos =vec3(10,20,-20);
    vec3 l=normalize(lightPos-p);
    vec3 n=GetNormal(p);
    float cosphi=dot(n,l);
    vec3 v=normalize(-l+2.*cosphi*n);
    vec3 col=GetColor(p);
    float po=15.;
    float amb=0.1;
    float t=pow(clamp(dot(v,-rd),0.,1.),po);
    col = (1.-t)*(amb+(1.-amb)*cosphi)*col+t*vec3(1.);
         
    //shadow
    t=shadow(p,l,SURF_DIST*2.,MAX_DIST,4.);
    col *=t;   
    
    //fog
    t=pow(min(d/MAX_DIST,1.),2.);
    col=(1.-t)*col+t*vec3(.9);
    
    glFragColor = vec4(col,1.0);
}

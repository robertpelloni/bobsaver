#version 420

// original https://www.shadertoy.com/view/7lsGz4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//Source code for interactive piece: "Touching Circles 1" Twitter: @smjtyazdi
//https://www.hicetnunc.xyz/objkt/95449

#define PI 3.14159265
#define DEL 0.002

#define R vec3(255,171,225)/255.
#define G vec3(255,230,230)/255.
#define B vec3(166,133,226)/255.
#define L vec3(250,245,245)/255.
#define Z vec3(0,0,0)/955.

float fx(vec2 r1 , vec2 r2,float r3){
    float d1 = 2.*sqrt(r1.x*r3);
    float d2 = 2.*sqrt(r2.x*r3);
    float sol1 = r1.y + d1;
    float sol2 = r1.y - d1;
    if(abs(abs(sol1-r2.y)-d2)<abs(r1.y-r2.y)/1000. )return sol1;
    return sol2;
}

float l(vec2 p,float r,float x){
    return length(p-vec2(x,r))/r-1.;
}

vec3 l2(vec2 p,float r,float x){
    return vec3(length(p-vec2(x,r))-r , atan(p.y-r,p.x-x),r);
}

bool check_in(vec2 p,float x1, float r1,float x2,float r2){
    if(p.x < min(x1,x2) || p.x>max(x1,x2))return false;
    if(p.y > (p.x-x1)*(r1-r2)/(x1-x2) + r1) return false;
    return true;
}

vec3 col(float i){
    if(i==1.)return R;
    if(i==2.)return B;
    if(i==3.)return G;
}

float trip(float x1,float x2){
    if(3.!=x1 && 3.!=x2)return 3.;
    if(1.!=x1 && 1.!=x2)return 1.;
    return 2.;
}

float big(float r1,float r2){
    return 1./pow(1./sqrt(min(r1,r2)) - 1./sqrt(max(r1,r2)),2.);
}

float smol(float r1,float r2){
    return 1./pow(1./sqrt(r2) + 1./sqrt(r1),2.);
}

vec4  render(vec2 p,float t){

    float sgn = sign(p.y);
    p.y = abs(p.y);
    
    float r1 = 100.;
    float ro = r1;
    float r2 = 1./(0.1+0.3*abs(0.5+0.5*cos(t/24. *2.*PI) ));//mouse*resolution.xy.x/resolution.x));
    float kappa = sqrt(r1/r2);
    if(abs(kappa*2.-round(kappa*2.))/2.<DEL) r2 = r1 / pow(round(kappa*2.)/2. + DEL ,2.);

    float x1 = 0.;
    float x2 = x1 + 2.*sqrt(r1*r2);

    if(l(p,r1,x1)<0.0)return vec4(1.,sgn*l2(p,r1,x1)) ;
    if(l(p,r2,x2)<0.0)return vec4(2.,sgn*l2(p,r2,x2));
    
    float c1 = 1.;
    float c2 = 2.;
    float c3 = 3.;
    
    float r3,x3;
    
    if(check_in(p,x1,r1,x2,r2))
        r3 = smol(r1,r2);
    else
        r3 = big(r1,r2);

    x3 = fx(vec2(r1,x1),vec2(r2,x2),r3);

    if(l(p,r3,x3)<0.0)return vec4(3.,sgn*l2(p,r3,x3));
    
   
    for(int i=0;i<80;i++){
 
       if(r3>r1||r3>r2){
            float rmax,xmax,cmax;
            float rmin,xmin,cmin;
            if(r1>r2){rmax=r1;xmax=x1;cmax=c1;rmin=r2;xmin=x2;cmin=c2;}
                else{ rmax=r2;xmax=x2;cmax=c2;rmin=r1;xmin=x1;cmin=c1;}
            if(check_in(p,x3,r3,xmin,rmin)){
                float r3_old=r3;
                x1 = x3; r1=r3; c1=c3;
                x2 = xmin; r2=rmin; c2=cmin;
                
                r3 = smol(rmin,r3);
                x3 = fx(vec2(r3_old,x3),vec2(rmin,xmin),r3);
                c3 = trip(cmin,c3);
                if(l(p,r3,x3)<0.0)return vec4(c3,sgn*l2(p,r3,x3));
            }
   
            else{
                if(!check_in(p,x3,r3,xmax,rmax)){
                    float r3_old=r3;
                    x1 = x3; r1=r3; c1=c3;
                    x2 = xmax; r2=rmax; c2=cmax;

                    r3 =big(r3,rmax);
                    x3 = fx(vec2(r3_old,x3),vec2(rmax,xmax),r3);
                    
                    
                    c3 = trip(cmax,c3);
                    if(l(p,r3,x3)<0.0)return vec4(c3,sgn*l2(p,r3,x3));
                }
                else break;

            }
                
       }
       
       else{
           if(check_in(p,x1,r1,x3,r3)){
           x2 = x3; r2 = r3;
           c2 = c3;
           }
           else{
               if(check_in(p,x2,r2,x3,r3)){
               x1 = x3; r1 = r3;
               c1 = c3;
               }
               else break;
           }

            r3 = 1./pow(1./sqrt(r1) + 1./sqrt(r2),2.);
            x3 = fx(vec2(r1,x1),vec2(r2,x2),r3);
            c3 = trip(c1,c2);

            if(l(p,r3,x3)<0.0)return vec4(c3,sgn*l2(p,r3,x3));
       }
    }
    
    return vec4(0.);

}

void main(void)
{
   vec2 p = (gl_FragCoord.xy  - resolution.xy/2.0)/resolution.y*1000.;
   float scale = 1.5; // *(0.5 + 1.* mouse*resolution.xy.y/resolution.y);
   p *= scale;

   vec3 colr;
   vec3 result = vec3(0.);
   for(float k=0.;k<3.;k+=1.){
       vec4 get = render(p,time - k/180.);
       if(get.x==0.)colr = Z;
       else {
           colr = col(get.x);
           vec2 pos = abs(1.-abs(get.y/get.w))*vec2(cos(get.z),sin(get.z));
           colr*=  3./(3. + pow(length(pos-vec2(-0.5,0.5) ),2.) );
           colr +=  0.02/(0.1 + length(pos-vec2(-0.5,0.5) ) )*L;
           colr*=min(abs(get.y/scale*1.5),1.);
        }
        result+=colr/(1.+k);
   }
   glFragColor = vec4(result/1.7,1.0);
}

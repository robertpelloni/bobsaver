#version 420

// original https://www.shadertoy.com/view/tlXcDS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAX_STEPS 100
#define MAX_DIST 100.
#define MIN_DIST .01

vec3 bgcolor=vec3(.5,.7,.9);

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

float plane(vec3 p){
     vec3(0,1,0);
    float d=p.y;
    return d;
}

float box( vec3 p, vec3 b, float r )
{  
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0) - r;
}

float sphere(vec3 p,vec3 m){
   // p.z= mod(p.z,10.);
   // p.x= mod(p.x,10.);
    float d=length(p-m)-2.;  
    return d;
}

float objdist(int k, vec3 p){
   
    if(k==0) return plane(p);
    if(k==1) return box(p-vec3(0,1.5,8),vec3(1),0.5);
    if(k==2) return sphere(p,vec3(5.*cos(time),2,8.+5.*sin(time)));

}
vec3 getcolor(vec3 p){
    float[20] d;
    vec3 planecol=vec3(.7,.7,.9);
    if((mod(p.x,10.) > 5. && mod(p.z,10.) > 5.)||(mod(p.x,10.) < 5. && mod(p.z,10.) < 5.)) 
        planecol=vec3(.5);
    vec3[] colors=vec3[](planecol,
                   vec3(0.9,0.3,0.3),
                   vec3(0));
    
    for(int k=0;k<3;++k) d[k]=objdist(k,p);
    
    float dist=MAX_DIST;
    vec3 color=bgcolor;    
    for(int i=0;i<3;i++){
        if(d[i]<dist){
            color=colors[i];
            dist=d[i];
        }
    }
    return color;
}

float getdist(vec3 p){
    float[20] d;
    
    for(int k=0;k<3;++k) d[k]=objdist(k,p);
    
    float dist=MAX_DIST;
    for(int i=0;i<3;i++){
        if(d[i]<dist){
            dist=d[i];
        }
    }
    return dist;
}

vec3 getnormal(vec3 p){
    float d=getdist(p);
    vec2 e=vec2(.01,0.);
    
    vec3 n=d-vec3(getdist(p-e.xyy),
                  getdist(p-e.yxy),
                  getdist(p-e.yyx));
    return normalize(n);
}

float raymarch(vec3 ro, vec3 rd){
    
    float dist = 0.;
    vec3 p = ro;
    
    for(int i=0; i < MAX_STEPS ; i++){
     float d=getdist(p);
        p += d*rd;
        dist += d;
        if(d < MIN_DIST || d > MAX_DIST) break;
    }
    
    return dist;
    
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (gl_FragCoord.xy-0.5*resolution.xy)/resolution.y;

    vec3 ro= vec3(0,6,-4);
    vec3 rd= normalize(vec3(uv.x,uv.y,1));
   // float alpha=(mouse*resolution.xy.x-.5*resolution.x)/resolution.x*3.14; 
   // float beta=(mouse*resolution.xy.y-.5*resolution.y)/resolution.y*3.14; 
    float beta=-.3;
    rd=rotateX(rd,-beta);
   // rd=rotateY(rd,-alpha);
    
    
    float d=raymarch(ro,rd);
    vec3 p=ro+d*rd;   
    vec3 l=vec3(3.,6,.0);
    vec3 n=getnormal(p);
    vec3 col=getcolor(p);   
    
    //reflecting sphere
    if(length(col)==0.){
      rd = normalize(rd-2.*dot(n,rd)*n);
      d=raymarch(p+n*MIN_DIST*2.,rd);
      p=p+d*rd;
      col=getcolor(p); 
      n=getnormal(p);  
    }
    
    vec3 pl = normalize(l-p);
    vec3 v = normalize(pl-2.*dot(n,pl)*n);
     
    
    //diffuse light
    float diff=clamp(dot(n,pl),0.,1.);
    
    col *=diff;
    
    //shadow
     if(d<MAX_DIST){
       float ds=raymarch(p+n*MIN_DIST*2.,pl);
       if( ds < length(l-p)) col=col*0.2;
     }
    
    //ambient light
    float amb=.2;
    col= clamp(amb*bgcolor+col,.0,1.);
   
    //reflection    
    float t=pow(clamp(dot(v,rd),0.,1.),20.);
    col=t*vec3(1)+(1.-t)*col;
    
    //light source
   // t=pow(clamp(dot(pl,rd),0.,1.),20.);
    //col=t*vec3(1)+(1.-t)*col;
    
    //fog
    t=pow(clamp(d/MAX_DIST,0.,1.),1.);
    col= t*bgcolor+(1.-t)*col;
     
    // Output to screen
    glFragColor = vec4(col,1.0);
}

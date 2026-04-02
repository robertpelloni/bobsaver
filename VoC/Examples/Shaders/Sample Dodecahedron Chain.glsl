#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/wstyWX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI acos(-1.)
#define pmod(p,n) (length(p)*sin(vec2(0,PI*.5)+mod(atan(p.x,p.y),PI*2./n)-PI/n))

mat3 lookat(vec3 eye, vec3 target, vec3 up){
    vec3 w=normalize(target-eye), u=normalize(cross(w,up));
    return mat3(u,cross(u,w),w);
}

void rot3(inout vec3 p,vec3 a,float t){
    a=normalize(a);
    vec3 u=cross(a,p),v=cross(u,a);
    p=u*cos(t)+v*sin(t)+a*dot(p,a);   
}

float map(vec3 p){
    rot3(p,vec3(1,2,3),time*.7);
    rot3(p,vec3(5,2,3),time*.5);
    float d=1e3;
    for(int i=0;i<6;i++){
        vec3 w=normalize(vec3(sqrt(5.)*.5+.5,(i&1)*2-1,0)); 
        w=vec3[](w,w.yzx,w.zxy)[i%3];
        vec3 up=-sign(w.x+w.y+w.z)*sign(w)*w.zxy;
        vec3 u=normalize(cross(w,up));
        //vec3 q=p*mat3(u,cross(u,w),w);
        vec3 q=vec3(dot(p,u),dot(p,cross(u,w)),dot(p,w));
        rot3(q,vec3(0,0,1),PI/5.);
        q.xy=pmod(q.xy,5.);
        q.x=abs(q.x);
        vec3 q0=q;
        float r=1.;
        q0.y-=r;
        d=min(d,length(vec2(length(q0.xy)-.15,q0.z))-.05);
        q.xy=vec2(atan(q.x,abs(q.y))*r, length(q.xy)-r);
        q.x-=clamp(q.x,.2,2.);
        d= min(d,length(q)-.05);
    }
    return d;
}

vec3 calcNormal(vec3 p){
  vec3 n=vec3(0);
  for(int i=0; i<4; i++){
    vec3 e=.001*(vec3(9>>i&1, i>>1&1, i&1)*2.-1.);
    n+=e*map(p+e);
  }
  return normalize(n);
}

void main(void)
{
    vec2 p=(2.*gl_FragCoord.xy-resolution.xy)/resolution.y;
    vec3 bg=vec3(1);
    vec3 ro0=vec3(0,0,2.5);
    vec3 ta=vec3(.1,.05,0);
    vec3 rd0=normalize(vec3(p,2.));
    vec3 sv=normalize(cross(ta-ro0,vec3(0,1,0)))*.04;
    float b=6.;  
    for (float j=0.; j<b; j++){
        vec3 ro = ro0+sv;
        vec3 rd = lookat(ro,ta,vec3(0,1,0)) * rd0;
        float z = 0.0, d, i, ITR=70.0;
         for( i = 0.0; i < ITR; i++){
            z += d = map(ro + rd * z);
            if(d < 0.001 || z > 30.0) break;
          }
        if(d < 0.001){
              vec3 p = ro + rd * z;
             vec3 nor = calcNormal(p);
            vec3 li = normalize(vec3(1));
            vec3 col = vec3(1.,.9,.8)*.7;
            col *= pow(1.-i/ITR,2.); 
                col *= clamp(dot(nor,li),.3,.8);
            col *= max(.5+.5*nor.y,0.);
            float rimd = pow(clamp(1.-dot(reflect(-li,nor),-rd),0.,1.),2.5);
            float frn = rimd+2.2*(1.0-rimd);
            col *= frn*.8;
            col += pow(clamp(dot(reflect(normalize(p-ro),nor),li),0.,1.),6550.);
            col *= exp(-z*z*0.05);
             col = min(vec3(1),col*2.);
            bg += col;
        }
        rot3(sv, normalize(ta-ro0), PI*2./b);
    }
    bg = clamp(bg/b,0.,1.);
    glFragColor.xyz = pow(bg,vec3(1.8));
}

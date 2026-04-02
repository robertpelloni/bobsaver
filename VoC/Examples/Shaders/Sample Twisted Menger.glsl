#version 420

// original https://www.shadertoy.com/view/fdBBzy

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#if HW_PERFORMANCE==1
//#define AA
#endif
//the max steps
#define MAX_STEPS 65536
//only used for computing normals
#define near 0.000001
#define far 1000.
#define COLOR_SPEED 0.1
//this number defines the number of subdivisions in the menger cube when computed for light. When not computing lights, the number of subdivions is infinite, and is only not sampled when epsilon has been reached, which is set dynamically based on the distance of the ray to the cube after the first epsilon(for the non-menger) has been reached, and the screen resolution.
#define MENGER_LIGHT_DENSITY 3.0
#define lerp(a, b, k) a*(1.0-k)+b*k

vec3 hue(float t){
    vec3 h=vec3(1,0,0);
    if (t<=0.333){
        h.r=0.333-t;
        h.g=t;
        h.b=0.;
    }
    else if(t<=0.667){
        h.g=0.667-t;
        h.b=t-0.333;
        h.r=0.;
    }
    else{
        h.b=1.-t;
        h.r=t-0.667;
        h.g=0.;
    }
    h*=3.;
    return h;
}
float cubeSDF(vec3 p,float f){
    vec3 v = abs(p) - vec3(f);
    return length(max(v,0.0)) + min(max(v.x,max(v.y,v.z)),0.0);
}

float mengerSDF(vec3 p, float limit){
    float r=1.;
    float II=0.;
    vec3 o=vec3(0);
    float d=0.0;
    
    float f;
    
    if(II==0.)d=cubeSDF(p+o,r);
    if (d>r*sqrt(2.0))return d;
    vec3 no=vec3(0);
    
    r/=3.;
    while (d<r*sqrt(2.0)&&(II<limit||limit==0.)){
        
        d=far;
        f=cubeSDF(p+o+vec3(2.*r,2.*r,0),r);if(f<d){d=f;no=o+vec3(2.*r,2.*r,0);}
        f=cubeSDF(p+o+vec3(2.*r,0,2.*r),r);if(f<d){d=f;no=o+vec3(2.*r,0,2.*r);}
        f=cubeSDF(p+o+vec3(0,2.*r,2.*r),r);if(f<d){d=f;no=o+vec3(0,2.*r,2.*r);}
        f=cubeSDF(p+o+vec3(2.*r,2.*r,2.*r),r);if(f<d){d=f;no=o+vec3(2.*r,2.*r,2.*r);}
        f=cubeSDF(p+o+vec3(2.*-r,2.*r,0),r);if(f<d){d=f;no=o+vec3(2.*-r,2.*r,0);}
        f=cubeSDF(p+o+vec3(2.*r,2.*-r,0),r);if(f<d){d=f;no=o+vec3(2.*r,2.*-r,0);}
        f=cubeSDF(p+o+vec3(2.*-r,2.*-r,0),r);if(f<d){d=f;no=o+vec3(2.*-r,2.*-r,0);}
        f=cubeSDF(p+o+vec3(2.*-r,0,2.*r),r);if(f<d){d=f;no=o+vec3(2.*-r,0,2.*r);}
        f=cubeSDF(p+o+vec3(2.*r,0,2.*-r),r);if(f<d){d=f;no=o+vec3(2.*r,0,2.*-r);}
        f=cubeSDF(p+o+vec3(2.*-r,0,2.*-r),r);if(f<d){d=f;no=o+vec3(2.*-r,0,2.*-r);}
        f=cubeSDF(p+o+vec3(0,2.*-r,2.*r),r);if(f<d){d=f;no=o+vec3(0,2.*-r,2.*r);}
        f=cubeSDF(p+o+vec3(0,2.*r,2.*-r),r);if(f<d){d=f;no=o+vec3(0,2.*r,2.*-r);}
        f=cubeSDF(p+o+vec3(0,2.*-r,2.*-r),r);if(f<d){d=f;no=o+vec3(0,2.*-r,2.*-r);}
        f=cubeSDF(p+o+vec3(2.*-r,2.*r,2.*r),r);if(f<d){d=f;no=o+vec3(2.*-r,2.*r,2.*r);}
        f=cubeSDF(p+o+vec3(2.*r,2.*-r,2.*r),r);if(f<d){d=f;no=o+vec3(2.*r,2.*-r,2.*r);}
        f=cubeSDF(p+o+vec3(2.*r,2.*r,2.*-r),r);if(f<d){d=f;no=o+vec3(2.*r,2.*r,2.*-r);}
        f=cubeSDF(p+o+vec3(2.*-r,2.*r,2.*-r),r);if(f<d){d=f;no=o+vec3(2.*-r,2.*r,2.*-r);}
        f=cubeSDF(p+o+vec3(2.*r,2.*-r,2.*-r),r);if(f<d){d=f;no=o+vec3(2.*r,2.*-r,2.*-r);}
        f=cubeSDF(p+o+vec3(2.*-r,2.*-r,2.*r),r);if(f<d){d=f;no=o+vec3(2.*-r,2.*-r,2.*r);}
        f=cubeSDF(p+o+vec3(2.*-r,2.*-r,2.*-r),r);if(f<d){d=f;no=o+vec3(2.*-r,2.*-r,2.*-r);}
        if(limit!=0.)II++;
        o=no;
        r/=3.;
        
        
    }
    //if(II>limit){
    //    return cubeSDF(p+o,r);
    //}
    return d;
    
    
    
     
}

bool PLANE=false;
float planeSDF( vec3 p, vec3 n,float d){
  return dot(p,n)+d;
}
vec3 PLANE_NORMAL=vec3(0,1,0);
float n(float t){
    
    float x=fract(t);
    return 2.*x*x-2.*x;
}
float dn(float t){
    float x=fract(t);
    return 4.*x-2.;
}
float sinl(float t){
    if(fract(t*0.5)>0.5)return n(t);
    return -n(t);
}
float dsinl(float t){
    if(fract(t*0.5)>0.5)return dn(t);
    return -dn(t);

}
float rand(float t){t=fract(t*.1031);t*=t+33.33333333;return  fract(t);}
float stars(vec3 p){
    p.y-=time;
    float d=400.-length(p);
    if(d<3.0)
    if(d>-3.0){
        vec3 o=p;
        p=mod(p-2.,4.)-1.-sinl(10.*p.y+10.*p.x+10.*p.z);
        return length(p)-0.1;
    }
    return abs(d);

}
#define PI 3.141592674
#define transform() \
    float a=sinl(p.y*0.2);\
    p*=mat3(cos(a),0,sin(a),\
            0,1,0,\
            -sin(a),0,cos(a));\
    p.xz+=1.;\
    a=p.y*0.5;\
    p*=mat3(cos(a),0,sin(a),\
            0,1,0,\
            -sin(a),0,cos(a));\
    p.y=mod(p.y,2.0)-1.0
vec2 sceneSDF(vec3 p, float limit){
    float strs=stars(p);
    transform();
    if(limit<1.){
        float mng=mengerSDF(p,limit);
        if(mng<strs)return vec2(mng,0.);
        return vec2(strs,1.);
    }else return vec2(mengerSDF(p,limit),0.);

}
float getEplison(float dist,float R){
    return clamp(5.*pow(dist*0.1,1.1)*R,0.00000001,0.1);
}
vec3 rayMarch(vec3 o, vec3 d, float start, float end, int max_steps, bool for_lights){
    float R=1.0/length(resolution.xy);
    float depth = start;
    float fd= 0.0005;
    float limit=0.0;
    bool a_bool=false;
    if(for_lights)limit=MENGER_LIGHT_DENSITY;
    for (int i = 0; i < max_steps; i++) {
        
        vec2 dist = sceneSDF(o + depth * d, limit);
        if(dist.y==0.&&!a_bool&&dist.x<0.0005){
            fd=getEplison(depth+dist.x,R);
            a_bool=true;
            //fd=0.0001;
            //if(!for_lights)limit=round(2./dist.x);
        }
        else if (dist.x < fd){
            //if(dist.y>0.9)
            return vec3(depth,dist.y,fd);
        }
        depth += dist.x*0.5;
        if (depth >= end)return vec3(end,0,fd);
    }
    return vec3(end,0,fd);
}

vec3 normal(vec3 p, float n){
    return normalize(vec3(sceneSDF(vec3(p.x+n,p.yz),0.).x-sceneSDF(vec3(p.x-n,p.yz),0.).x,
                sceneSDF(vec3(p.x,p.y+n,p.z),0.).x-sceneSDF(vec3(p.x,p.y-n,p.z),0.).x,
                sceneSDF(vec3(p.xy,p.z+n),0.).x-sceneSDF(vec3(p.xy,p.z-n),0.).x
           ));
}

float softShadow(vec3 ro, vec3 rd, float mint, float maxt, float k )
{
    float res = 1.0;
    for( float t=mint; t<maxt; )
    {
        float h = sceneSDF(ro + rd*t, MENGER_LIGHT_DENSITY).x;
        if( h<mint*0.1 )
            return 0.0;
        res = min( res, k*h/t );
        t += h;
        
    }
    return res;
}
float light_func(vec3 p, vec3 light, bool shadows){
    float len=dot(light-p,light-p);
    float f=1.0/len;
    if(shadows){
        float y=rayMarch(p,normalize(light-p),0.01,100.,128,true).x;
        if(y<len)return 0.;
    }
    if(f<0.)return 0.;
    return f;
}
float dist_light_func(vec3 p, vec3 normal, vec3 light,bool shadows){
    light=normalize(light);
    float len=dot(normal,light);
    float f=len;
    if(PLANE)f+=10.*pow(len,15.);
    if(shadows){
        float k=4.;
        if(PLANE)k=64.;
        f*=softShadow(p,light.xyz, 4.,128.,k);
    }
    if(f<0.)return 0.;
    return f;
}
#define world vec3(0.0001,0.001,0.001*(uv.y+0.7))
void main(void)
{
    glFragColor.rgb=vec3(0);
    //this gives it time
    if(time>0.1){
        vec2 mouse=mouse*resolution.xy.xy/resolution.xy;
        if(mouse*resolution.xy.x==0.)mouse+=1.;
        else mouse+=0.4;
        vec3 col=hue(mod(time*COLOR_SPEED,1.0));
        
        float dist=(sin(0.25*time)*0.3+2.)*8.3*(pow(mouse.y,4.)+0.1);
        vec3 o=vec3(sin(time-mouse.x*6.)*dist,time,cos(time-mouse.x*6.)*dist);

        vec2 uv = (gl_FragCoord.xy/resolution.xy-0.5)*normalize(resolution.xy);
        vec3 d=normalize(vec3(uv,1.1));
        vec3 a = vec3(normalize(-o.xz),0);
        a=vec3(a.x,0,a.y);
        vec3 b = cross(a, vec3(0,1,0));
        vec3 c = cross(b, a);
        mat3 cm=mat3(b,c,a);
        d*=cm;
        vec3 f=world;
        d=normalize(d);
        vec3 t=rayMarch(o,d,0.0018,far,MAX_STEPS, false);
        vec3 p=o+d*t.x;
        if (t.x<far){
            
            vec3 albedo=vec3(0);
            int NG,SG;
            if(t.y>0.9){
                NG=1;
                SG=1;
            }
            else{
                NG=9;
                SG=3;
            
            }
            
            if(t.y<0.1){
#ifdef AA
                for(int i=0;i<NG;i++){
                    d=normalize(vec3(uv,1.1));
                    uv = ((gl_FragCoord.xy+0.1*vec2(i/SG,i%SG))/resolution.xy-0.5)*normalize(resolution.xy);
                    d*=cm;
                    d=normalize(d);
                
#endif
                    p=o+d*t.x;
                    f=world;
                    
                    vec3 N;
                    f*=albedo;
                    albedo=vec3(0.04,0.1,0.2);
                    N=normal(p,t.z);

                    float l=dist_light_func(p,N,vec3(0,1,0.5),true);
                    f.rgb+=albedo*2.*vec3(0.2,0.15,0.15)*l;
                    f.rgb+=0.1*pow(l,10.);

                    l=dist_light_func(p,N,vec3(0,1,-0.5),true);
                    f.rgb+=albedo*2.*vec3(0.2,0.15,0.15)*l;
                    f.rgb+=0.1*pow(l,10.);
                    
                    vec3 o=p;
                    transform();
                    float Q=1.0/dot(p.xz,p.xz);
                    //f.rgb+=vec3(1.,0.01,0.001)*albedo*Q;
                    f.rgb+=col*albedo*Q;
                    p=o;

                    //f.rgb=N*0.5+0.5;
#ifdef AA
                    glFragColor.rgb+=(1./float(NG))*f;
                }
                
#endif
                
            }else{
                 
                 /*f+=rand(d.x*100.)*vec3(0,1,0.2);
                 f+=rand(d.y*99.+d.x*98.)*0.5;
                 f+=rand(d.y*99.+d.x*98.)*0.5;
                 f+=(rand(d.x*99.+d.y*98.)*2.-1.)*vec3(2,0.02,0);*/
                 glFragColor.rgb=f;
            
            }

        }
#ifdef AA
        else{
            glFragColor.rgb=world;     
        }
#endif 
#ifndef AA
        glFragColor.rgb=f;
#endif

        glFragColor.rgb=sqrt(glFragColor.rgb);
        glFragColor.rgb-=length(mod(gl_FragCoord.xy,3.))*0.01;
        
    }
}

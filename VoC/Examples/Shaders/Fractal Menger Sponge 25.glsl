#version 420

// original https://www.shadertoy.com/view/ssBBDD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/**
 *  FULL MENGER SPONGE by Louis Sarwal
 *
 *  
 * I am the sole copyright owner of this Work.
 * You cannot host, display, distribute or share this Work in any form,
 * including physical and digital. You cannot use this Work in any
 * commercial or non-commercial product, website or project. You cannot
 * sell this Work and you cannot mint an NFTs of it.
 *
**/

#if HW_PERFORMANCE==1
//uncomment this if you have a decent GPU. It improves the sponge s lot.
//#define AA
#endif
//the max steps
#define MAX_STEPS 65536
//only used for computing normals
#define near 0.000001
#define far 100.
#define COLOR_SPEED 0.1
//this number defines the number of subdivisions in the menger cube when computed for light. When not computing lights, the number of subdivions is infinite, and is only not sampled when epsilon has been reached, which is set dynamically based on the distance of the ray to the cube after the first epsilon(for the non-menger) has been reached, and the screen resolution.
#define MENGER_LIGHT_DENSITY 4.0
#define lerp(a, b, k) a*(k-1.0)+b*k
vec3 hue(float t){
    vec3 h=vec3(1,0,0);
    if (t<0.333){
        h.r=(0.333-t)*3.;
        h.g=(t)*3.;
        h.b=0.;
        return h;
    }
    else if(t<0.667){
        h.g=(0.667-t)*3.;
        h.b=(t-0.333)*3.;
        h.r=0.;
    }
    else{
        h.b=(1.-t)*3.;
        h.r=(t-0.667)*3.;
        h.g=0.;
    }
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
    if (d>r*1.414213562)return d;//1.414213562=sqrt(2)
    vec3 no=vec3(0);
    
    r/=3.;
    while (d<r*1.414213562&&(II<limit||limit==0.)){
        
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
vec4 noise(vec3 p){
    float f=sin(p.z*0.3)+sin(p.x*0.3)+sin(p.x)+sin(p.y)+sin(p.z)+sin(p.x+p.z)+sin(p.y+p.x)+sin(p.z+p.y);
    f*=0.5;
    vec3 d=normalize(vec3(
        0.3*cos(p.x*0.3)+cos(p.x)+cos(p.x+p.z)+cos(p.x+p.y),
        cos(p.y)+cos(p.x+p.y)+cos(p.y+p.z),
        0.3*sin(p.z*0.3)+cos(p.z)+cos(p.x+p.z)+cos(p.y+p.z)
        
        ));//no coefficient, as it is normalized
    return vec4(f,d);
}

const mat3 m3=mat3(-0.5, 0.9, 0.5,
                0.4, -0.5, 0.4,
                0.5, 0.9, -0.5);

vec4 fbm( in vec3 x, int octaves )
{
    float f = 2.0; 
    float s = 0.5;  
    float a = 0.0;
    float b = 0.5;
    vec3  d = vec3(0.0);
    mat3  m = mat3(1.0,0.0,0.0,
    0.0,1.0,0.0,
    0.0,0.0,1.0);
    for( int i=0; i < octaves; i++ )
    {
        vec4 n = noise(x);
        a += b*n.x;          // accumulate values
        d += b*m*n.yzw;      // accumulate derivatives
        b *= s;
        x = f*m3*x;
        m = f*m3*m;
    }
    return vec4( a, d );
}
bool PLANE=false;
float planeSDF( vec3 p, vec3 n,float d){
  return dot(p,n)+d;
}
vec3 PLANE_NORMAL=vec3(0);
float n(float t){
    float x=fract(t);
    return (1.-x)*(1.-x)+x*x;
}
vec2 sceneSDF(vec3 p, float limit){
    vec3 distort=vec3(n(p.y*0.5+0.5)+n(p.z*0.5+0.5),n(p.x*0.5+0.5)+n(p.z*0.5+0.5),n(p.y*0.5+0.5)+n(p.x*0.5+0.5));
    float mng=mengerSDF(p*distort,limit);
    //vec4 n=fbm(p+time*2.,9);
    //float pln=planeSDF(p,vec3(0,1,0),2.+n.x);
    //PLANE_NORMAL=normalize(n.yzw);
    //if(mng<pln){
    //    PLANE=false;
    return vec2(mng,0.);
    //}
    //else{
    //    PLANE=true;
    //    return vec2(pln,1.);
    //}
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
        depth += dist.x*0.4;//bad, but it gets around the broken distance field
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
    //f.rgb=N;
    if(shadows){
        float y=rayMarch(p,normalize(light-p),0.01,100.,128,true).x;
        if(y<len)return 0.;
    }
    if(f<0.)return 0.;
    return f;
}
float dist_light_func(vec3 p, vec3 normal, vec3 light,bool shadows){
    light.xyz=normalize(light);
    float len=dot(normal,light);
    float f=len;
    if(PLANE)f+=10.*pow(len,15.);
    //f.rgb=N;
    if(shadows){
        float k=4.;
        if(PLANE)k=64.;
        f*=softShadow(p,light.xyz, 4.,128.,k);
    }
    if(f<0.)return 0.;
    return f;
}

void main(void)
{
    glFragColor.rgb=vec3(0);
    //this gives it time
    if(time>0.1){
        vec2 mouse=mouse*resolution.xy.xy/resolution.xy;
        if(mouse*resolution.xy.x==0.)mouse+=0.9;
        vec3 col=hue(mod(time*COLOR_SPEED,1.0))*0.07;
        
        float dist=(sin(0.25*time)*0.3+0.7)*7.3*(mouse.y*mouse.y+0.1);
        vec3 o=vec3(sin(time-mouse.x*6.)*dist,0,cos(time-mouse.x*6.)*dist);

#ifdef AA

        
        for(int i=0;i<4;i++){
            vec2 uv = ((gl_FragCoord.xy+0.5*vec2(i/2,i%2))/resolution.xy-0.5)*normalize(resolution.xy);
#else
            vec2 uv = (gl_FragCoord.xy/resolution.xy-0.5)*normalize(resolution.xy);
#endif

            vec3 d=normalize(vec3(uv,1.1));
            vec3 f=vec3(0.3,0.35,0.4);
            vec3 a = normalize(vec3(0,0,0)-o);
            vec3 b = cross(a, vec3(0,1,0));
            vec3 c = cross(b, a);
            mat3 cm=mat3(b,c,a);
            d*=cm;
            d=normalize(d);
            vec3 t=rayMarch(o,d,0.0018,far,MAX_STEPS, false);
            if (t.x<far){
                vec3 p=o+d*t.x;
                vec3 N;
                vec3 albedo=vec3(0);
                
                if(t.y>0.9){
                    albedo=vec3(0.04,0.06,0.14)+clamp(-p.y*0.1-0.2,0.0,1.0);
                    N=PLANE_NORMAL;
                }
                else {
                    albedo=vec3(0.4);
                    N=normal(o+d*t.x,t.z);
                }

                f.rgb*=albedo*0.1*vec3(dot(N,vec3(0,1,-1)));
                t.z=clamp(t.z,0.01,0.1);
                f.rgb+=albedo*dist_light_func(p,N,vec3(0.5,0.5,0.5),true)*vec3(0.3,0.5,0.6);
                f.rgb+=albedo*light_func(p,vec3(0,0,0),false)*col*1.;
                //f.rgb=N*0.5+0.5;

            }
            #ifdef AA
            glFragColor.rgb+=f*0.25;
            #else
            glFragColor.rgb=f;
            #endif

#ifdef AA
        }
#endif

        glFragColor.rgb=sqrt(glFragColor.rgb);
    }
}

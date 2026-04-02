#version 420

// original https://www.shadertoy.com/view/XtGXDh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define BMIN vec3(1.0)
#define BMAX vec3(5.0,5.0,5.0)
#define GROUND vec4(0.0,1.0,0.0,-1.0)

bool collidePlane(vec3 P,vec3 V,vec4 plane, out float t) {    
    float d=plane.w;
    vec3 N=plane.xyz;
    float NPd=dot(N,P)+d;
    float NV=dot(N,V);
  
    //P below/on or V parallel/away
    if(NPd <= 0.0 || NV >= 0.0) {
        t=0.0;
        return false;
    }
    
    //
    t=-NPd/NV;
    return true;
}

bool collideBox(vec3 P,vec3 V,vec3 bMin,vec3 bMax, out float t) {
    //from gamedev.net/topic/682750-problem-with-raybox-intersection-in-glsl/#entry5313405
    //from gamedev.net/resources/_/technical/math-and-physics/intersection-math-algorithms-learn-to-derive-r3033
    //from tavianator.com/fast-branchless-raybounding-box-intersections-part-2-nans

    vec3 invRay=1.0/V;
    vec3 tmin = (bMin - P) * invRay;
    vec3 tmax = (bMax - P) * invRay;
    vec3 tnear = min(tmin, tmax);
    vec3 tfar = max(tmin, tmax);

    float enter = max(tnear.x, max(tnear.y, tnear.z)); //max(tnear.x, 0.0)
    float exit = min(tfar.x, min(tfar.y, tfar.z));

    t=enter;
    return exit > max(enter, 0.0); //exit>0.0 && enter<exit
}

vec3 boxNormal(vec3 bMin,vec3 bMax, vec3 colPt) {
    //checks the colPt against a plane for each face
    
    vec3 pMin=abs(colPt-bMin);
    vec3 pMax=abs(colPt-bMax);
 
    float eps=0.00001;

      if(pMax.x<eps) {return vec3(1.0,0.0,0.0);} 
      else if(pMin.x<eps) {return vec3(-1.0,0.0,0.0);}
      else if(pMax.y<eps) {return vec3(0.0,1.0,0.0);} 
      else if(pMin.y<eps) {return vec3(0.0,-1.0,0.0);}
      else if(pMax.z<eps) {return vec3(0.0,0.0,1.0);} 
      else if(pMin.z<eps) {return vec3(0.0,0.0,-1.0);} 
      else {return vec3(0.0);}
    
}

vec3 calcPtLightCol(vec3 pos, vec3 nor, vec3 lightPos,vec3 lightAtten,
                    vec3 lightCol,vec3 mtrlCol,float shininess,
                    float strength) {
    vec3 lightDir=lightPos.xyz-pos;
    float lightDist=length(lightDir);
    lightDir=lightDir/lightDist;

    //
    float a = 1.0/(lightAtten.x+lightAtten.y*lightDist+lightAtten.z*lightDist*lightDist);

    vec3 reflectVec=reflect(-lightDir,nor);
    float NdotL = max(0.0,dot(nor,lightDir));
    float spec=0.0;

    if(NdotL > 0.0) {
        float NdotR = max(0.0, dot(nor, reflectVec));
        spec = pow(NdotR, shininess*128.0) * strength*a;
    }

    float diffuse=NdotL*a;
    return lightCol*(mtrlCol*diffuse+spec);
}

float calcFlare(vec3 ro,vec3 rd,vec3 lightPos,float size) {
    vec3 viewLightDir=normalize(lightPos-ro);
    float viewLightDist=length(lightPos-ro);
    float q = dot(rd,viewLightDir)*0.5+0.5;
    float o = (1.0/viewLightDist)*size;
    return clamp(pow(q,900.0/o)*1.0,0.0,2.0);
}

bool collideScene(vec3 ro,vec3 rd,out vec3 colPt, out vec3 nor) {
    float t=9999999.0,t2;
    bool hit=false;

    vec3 bMin=BMIN;
    vec3 bMax=BMAX;
    vec4 plane=GROUND;
    
    if(collidePlane(ro,rd,plane,t2) && t2 < t) {
        t=t2;
        colPt=ro+rd*t;
        nor=plane.xyz;
        hit=true;
    } 
    
    if(collideBox(ro,rd,bMin,bMax, t2) && t2 < t) {
        t=t2;
        colPt=ro+rd*t;
        nor=boxNormal(bMin,bMax,colPt);
        hit=true;
    }
    
    return hit;
}

bool collideSceneP(vec3 ro,vec3 rd,out float t) {
    t=9999999.0;
    float t2;
    bool hit=false;

    vec3 bMin=BMIN;
    vec3 bMax=BMAX;
    vec4 plane=GROUND;
    
    if(collidePlane(ro,rd,plane,t2) && t2 < t) {
        t=t2;
        hit=true;
    } 
    
    if(collideBox(ro,rd,bMin,bMax, t2) && t2 < t) {
        t=t2;
        hit=true;
    }
    
    return hit;
}

vec3 checkerCol(vec3 texc, vec3 color0, vec3 color1) {
    float q=clamp(mod(dot(floor(texc),vec3(1.0)),2.0),0.0,1.0);
    return color1*q+color0*(1.0-q);
}

vec3 render(vec3 ro, vec3 rd) {
    vec3 lightCol=vec3(1.0,0.9,0.8);
    vec3 lightAtten=vec3(0.6,0.01,0.001);
    vec3 lightPos=vec3(cos(time)*11.0,8.0,sin(time)*11.0);

    vec3 col=vec3(0.0);
    vec3 pt,nor;
    bool hasHit=false;
    
    if(collideScene(ro,rd, pt,nor)) {
        vec3 matCol=checkerCol(pt*0.5,vec3(0.5),vec3(0.8));
        float tt,shd=1.0;
        shd=(collideSceneP(lightPos,normalize(pt-lightPos),tt) && tt<length(pt-lightPos)-0.0001)?0.01:1.0;
        vec3 light=calcPtLightCol(pt,nor,lightPos,lightAtten,lightCol,matCol,1.0,0.2);
        vec3 amb=clamp(light,0.0,0.05)*matCol;
        col+=light*shd+amb;
        hasHit=true;
    }

    if(!hasHit || length(ro-lightPos)<length(ro-pt)) {
        col=mix(col,lightCol*1.5,calcFlare(ro,rd,lightPos,0.15));
    }
    
    return vec3(clamp(col,0.0,1.0));
}

vec3 calcPrimaryRay(vec2 screen,float fovy,float aspect) {
    float d=1.0/tan(fovy/2.0);
    vec3 v=vec3(screen.x*aspect,screen.y,-d);
    v=normalize(v);
    return v;
}

mat3 orbitViewRot(float yaw,float pitch) {
    vec2 s=vec2(sin(pitch),sin(yaw));
    vec2 c=vec2(cos(pitch),cos(yaw));
    return mat3(c.y,0.0,-s.y, s.y*s.x,c.x,c.y*s.x, s.y*c.x,-s.x,c.y*c.x);
}

void main(void) {
    float fovy=0.7854;
    float aspect=resolution.x/resolution.y;
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    vec2 scr = uv*2.0-1.0;
    vec2 ms = mouse*resolution.xy.xy / resolution.xy;
    vec2 ms2=(ms.x==0.0 && ms.y==0.0)?vec2(0.5,0.5):ms;
    ms2=vec2(0.5,0.5);

    float pitch=(ms2.y-0.5)*5.0-0.7;
    float yaw=(ms2.x-0.5)*5.0;

    mat3 viewRot=orbitViewRot(yaw,pitch);

    vec3 ro=viewRot*vec3(0.0,2.0,25.0);
    vec3 rd=normalize(viewRot*calcPrimaryRay(scr,fovy,aspect));

    vec3 col=render(ro,rd);

    if(length((uv-ms)*vec2(aspect,1.0)) < 0.01) {
        col=mix(col,vec3(1.0),0.2);
    }

    glFragColor=vec4(col,1.0);
}

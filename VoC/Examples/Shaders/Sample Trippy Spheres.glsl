#version 420

// original https://www.shadertoy.com/view/3lyXDy

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

int MAX_STEPS = 2000;
float SURF_DIST = .05;
float MAX_DIST = 5000.;
vec3 modv = vec3(3., 6., 6.);

vec3 rand33(vec3 v){

    return vec3(0.);
    
}

vec3 world2modSpace(vec3 p){
    
    
    if(modv.x > 0.){
        p.x = mod(p.x-modv.x/2., modv.x)-modv.x/2.;
    }
    
    if(modv.y > 0.){
        p.y = mod(p.y-modv.y/2., modv.y)-modv.y/2.;
    }
    
    if(modv.z > 0.){
        p.z = mod(p.z-modv.z/2., modv.z)-modv.z/2.;
    }
    
    
    return p;
}

vec3 world2cellSpace(vec3 p){
    
    vec3 i = vec3(0);
    
    if(modv.x > 0.){
        i.x = floor((p.x+modv.x/2.)/modv.x);
    }
    if(modv.y > 0.){
        i.y = floor((p.y+modv.y/2.)/modv.y);
    }
    if(modv.z > 0.){
        i.z = floor((p.z+modv.z/2.)/modv.z);
    }
    
    
    return i;
}

vec3 rotateVec3(vec3 v, float thet, float phi){
    vec3 v1 = vec3(v.x*cos(thet)-v.y*sin(thet), v.x*sin(thet)+v.y*cos(thet), v.z);  
    return vec3(v1.x*cos(phi)-v1.z*sin(phi), v1.y , v1.x*sin(phi)+v1.z*cos(phi));
}

float distToPyramid( vec3 p, float s)
{
      p = abs(p);
    if(p.z<0.){
        float angle = atan(p.y/p.x);
        float thet = mod(angle, 3.1415/4.)*sign(sin(angle*4.))+3.1415*(1.-sign(sin(angle*4.)))/8.;
        float l = s*sqrt(2.)/(2.*cos(thet));
        if(length(p.xy)<l){
            return length(p.z);
        }else{
            return length(p-sign(p.x)*vec3(l*sin(angle), l*cos(angle), 0.));
        }
        
    }else{
        p = abs(p);
        return (p.x+p.y+p.z-s)*0.57735027;
    }
    
}

float distToSphere(vec3 p, vec3 sc, float r){
    vec3 D = p-sc;
    float L = length(D);   
    return L-r;
}

float getDist(vec3 p){
    
    vec3 modp = world2modSpace(p);
    vec3 ip = world2cellSpace(p);
    //float dS1 = distToSphere(p, vec3 (0.,0.,0.), 1.);
    float dS0 = distToSphere(modp, vec3 (0.,0.,0.), abs(0.75*sin(3.*ip.x+time)));
    float dS1 = distToPyramid(rotateVec3(modp, 3.1415/2., -sign(ip.y-0.1)*1.*time+length(ip)/17.154), 0.75);
    //float dS1 = 100.;
    float dS2 = distToSphere(modp, vec3 (0.,0.,1.), .25);
    float dS3 = distToSphere(modp, vec3 (0.,0.,-1.), .25);
    return dS0;
    //return min(dS1,min(dS2,dS3));
}

vec3 getNormal(vec3 p){
    
    float d = getDist(p);
    
    vec3 n = vec3(0.);
    vec2 e = vec2(.01,0.);
    
    if(d < 2.*SURF_DIST){
        n = d - vec3(getDist(p-e.xyy),getDist(p-e.yxy),getDist(p-e.yyx));
        n = normalize(n);
    }
    
    //if(length(p)>= MAX_DIST-SURF_DIST) n = vec3(0.0);
    return n;
}

float RayMarch(vec3 rp, vec3 rd){
    
    float dO = 0.;
    
    for(int i = 0; i<MAX_STEPS; i++){
        vec3 p = rp+rd*dO;
        float d = getDist(p);
        
        dO += d;
        
        if(dO > MAX_DIST || d < SURF_DIST) break;
        
    }
      
    return dO;
}

void main(void)
{ 
    float t = time;
    vec2 uv = (gl_FragCoord.xy-0.5*resolution.xy)/(resolution.x*0.5);
    vec3 cp = vec3(t,modv.y/2.,modv.z/2.);
    vec3 cd = normalize(vec3(1.0, 0.*cos(t/5.), 0.*sin(t/5.)));
    vec3 cu = normalize(vec3(0.,sin(time/15.),cos(time/15.)));
    
    float fov = 45.*3.1415/360.;
    float dov = 1./tan(fov);
    
    vec3 cx = normalize(cross(cu, cd));
    vec3 cy = normalize(cross(cd, cx));
    
    vec3 rd = normalize(dov*cd+uv.x*cx+uv.y*cy);
    
    float d = RayMarch(cp, rd);
    
    vec3 n = getNormal(cp+rd*d);
    
    vec3 i = world2cellSpace(cp+rd*d);
    
    // Output to screen
    glFragColor = vec4(abs(rotateVec3((1.+n)/2., length(i)/5. ,length(i)/5.)),1.);
    
}

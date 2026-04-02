#version 420

// original https://www.shadertoy.com/view/WttSzn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const int MAXD = 400;
const float EPSI  =0.0001;
int matId = 0;
mat2 rotate(float a){
    return mat2(cos(a),-sin(a),
                sin(a),cos(a));
}

float sm( float d1, float d2, float k ) {
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h); }

float sdSphere(vec3 p,float size){
    return length(p)-size;
}

float map(vec3 p,bool id){
    float smo = 2.;
    float sphere = sdSphere(p,1.);
    float sphere2 = sdSphere(p+vec3(sin(time)*2.,sin(time)*2.,sin(time)*2.),0.4);
    float sphere3 = sdSphere(p+vec3(sin(time)*2.,sin(time)*2.,cos(time)*4.),0.4);
    float sphere4 = sdSphere(p+vec3(sin(time)*2.,cos(time)*4.,sin(time)*2.),0.4);
    float sphere5 = sdSphere(p+vec3(sin(time)*2.,cos(time)*4.,cos(time)*4.),0.4);
    float sphere6 = sdSphere(p+vec3(cos(time)*4.,sin(time)*2.,sin(time)*2.),0.4);
    float sphere7 = sdSphere(p+vec3(cos(time)*4.,sin(time)*2.,cos(time)*4.),0.4);
    float sphere8 = sdSphere(p+vec3(cos(time)*4.,cos(time)*4.,sin(time)*2.),0.4);
    float sphere9 = sdSphere(p+vec3(sin(time)*4.,sin(time)*4.,sin(time)*4.),0.4);
    float sphere10 = sdSphere(p-vec3(sin(time)*2.,sin(time)*2.,sin(time)*2.),0.4);
    float sphere11 = sdSphere(p-vec3(sin(time)*2.,sin(time)*2.,cos(time)*4.),0.4);
    float sphere12 = sdSphere(p-vec3(sin(time)*2.,cos(time)*4.,sin(time)*2.),0.4);
    float sphere13 = sdSphere(p-vec3(sin(time)*2.,cos(time)*4.,cos(time)*4.),0.4);
    float sphere14 = sdSphere(p-vec3(cos(time)*4.,sin(time)*2.,sin(time)*2.),0.4);
    float sphere15 = sdSphere(p-vec3(cos(time)*4.,sin(time)*2.,cos(time)*4.),0.4);
    float sphere16 = sdSphere(p-vec3(cos(time)*4.,cos(time)*4.,sin(time)*2.),0.4);
    float sphere17 = sdSphere(p-vec3(sin(time)*4.,sin(time)*4.,sin(time)*4.),0.4);
    

    float plane =1.-(length(p)-550.);
    float sp = sm(sphere9,sm(sphere8,sm(sphere7,sm(sphere6,sm(sphere5,sm(sphere4,sm(sphere3,sm(sphere2,min(sphere,plane),smo),smo),smo),smo),smo),smo),smo),smo);
    float sp2 = sm(sphere17,sm(sphere16,sm(sphere15,sm(sphere14,sm(sphere13,sm(sphere12,sm(sphere11,sm(sphere10,min(sphere,plane),smo),smo),smo),smo),smo),smo),smo),smo);
    float mn = min(sp,sp2);
    if(id){
       
        if(mn == plane){
            matId = 3;
        }
        else{
            matId = 2;
        }
    }
    return  mn;
}

vec3 normal(vec3 p){
    vec2 e = vec2(EPSI,0);
    return normalize(vec3(map(p+e.xyy,false)-map(p-e.xyy,false),
                            map(p+e.yxy,false)-map(p-e.yxy,false),
                            map(p+e.yyx,false)-map(p-e.yyx,false)));
}
vec3 rayMarch(vec3 ro,vec3 rd, bool id){
    
    float tot = 0.;
    float dst = 0.;
    vec3 p;
    for(int i = 0; i<MAXD; i++){
        p = ro+rd*tot;
        dst = map(p,id);
        tot+=dst;
        if(dst<EPSI || tot > float(MAXD)){
            break;
        }
    }
    if(dst > EPSI){
       // matId = 1;
    }
    return p;
}
vec3 light(vec3 p,vec3 ro){
    vec3 lightCol = vec3(1);
    vec3 objCol = vec3(0);
    vec3 lightPos = vec3(10,10,12);
    vec3 viewDir = normalize(ro-p);
    vec3 l = normalize(lightPos - p);
    vec3 n = normal(p);
    vec3 reflectDir = reflect(-l,n);
    float diff = max(dot(l,n),0.);
    float spec = pow(max(dot(viewDir,reflectDir),0.),25.);
    float spcStr = 3.;    
    float ambi = 0.45;
    

    
    bool rm = length(rayMarch(p+n*EPSI*2.,l,false))<length(lightPos-p);
    if(rm){
        diff *= 0.1;
    }
    if(matId == 2){
        objCol = vec3(1,0.9,0.);
    }
    
    else if(matId == 3){
    
        objCol = vec3(0,0,0);
    }
    vec3 diffuse = lightCol*diff;
    vec3 ambient = ambi*lightCol;    
    vec3 specular = spcStr*spec*lightCol;
    return (ambient+diffuse+specular)*objCol;
}

void main(void) {
    vec2 uv = (gl_FragCoord.xy-0.5 * resolution.xy)/resolution.x;
    vec3 ro = vec3(0,0,-20);
    vec3 rd = normalize(vec3(uv,1.));
    ro.zy*=rotate(time*2.);
    rd.zy*=rotate(time*2.);
    ro.xz*=rotate(time);
    rd.xz*=rotate(time);
    
    vec3 p = rayMarch(ro,rd,true);
    vec3 color = (light(p,ro));
    if(matId == 1){
        color = vec3(0);
    }
    glFragColor = vec4(color,1.0);
}

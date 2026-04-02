#version 420

// original https://www.shadertoy.com/view/WtK3Rc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAX_DST 150
#define EPSI 0.001
int mat = 0;
float random(vec2 p){
    return(fract(sin(p.x*431.+p.y*707.)*7443.));
}
float noise(vec2 uv){
     vec2 id = floor(uv*10.);
    vec2 lc = smoothstep(0.,1.,fract(uv*10.));
    
    float a = random(id);
    float b = random(id + vec2(1.,0.));
    float c = random(id + vec2(0.,1.));
    float d = random(id + vec2(1.,1.));
    
    float ud = mix(a,b,lc.x);
    float lr = mix(c,d,lc.x);
    float fin = mix(ud,lr,lc.y);
    return fin;
}

float octaves(vec2 uv,int octs){
    float amp = 0.5;
    float f = 0.;
    for(int i =1; i<octs+1;i++){
        f+=noise(uv)*amp;
        uv*=2.;
        amp*=0.5;
    }
    return f;
}
mat2 rotate(float a){
    return mat2(cos(a),-sin(a),
                sin(a),cos(a));
}

float sphere(vec3 p){
    float r = 1.;
    r*=1.-(sin(p.y*20.+time*22.)*0.001)*20.;
    r*=1.-(cos(p.x*10.+time*22.)*0.001)*50.;

    return length(p)-r;
}

float sdBox( vec3 p, vec3 b ){
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float map(vec3 p){
    float sph = sphere(p+vec3(-10.,-6.5,-3.-time*62.));
    float plane = p.y+8.+octaves((p.xz/30.)+(time/10.)+sin(length(p.xz*2.))*.04,10);
    float c = 20.;
    float c2 = 8.;
    p.x+=sin(p.z*0.2);
    p.x=mod(p.x+c*.5,c)-c*.5;
    p.z=mod(p.z+c2*.5,c2)-c2*.5;
 
    return  min(min(sph,min(sdBox(p,vec3(0.5,4.0,1)),sdBox(p+vec3(0,-4.5,0),vec3(1.5,0.5,4)))),plane);
}

void main(void) {
    
    vec2 uv = (gl_FragCoord.xy-0.5*resolution.xy)/resolution.y;

    vec3 col = vec3(0);
    vec3 ro = vec3(10,7,-5);
    vec3 rd = normalize(vec3(uv,1.));
    ro.yz*=rotate(.3);
    rd.yz*=rotate(.3);
   
    ro.z+=time*62.;
    ro.x+=sin(time)*4.;
    ro.y+=cos(time)*2.;
  
    float tot = 0.;
    float dst = 0.;
    float shad = 0.;
    vec3 p = vec3(0.) ;
    mat = 0;
    for(int i =0;i<MAX_DST;i++){
        p = ro+rd*tot;
        dst = map(p);
        tot+=dst;    
        if(dst<EPSI){
            shad = float(i)/float(MAX_DST);
            break;
        }
    }
    if(dst>EPSI){
        mat = 1;
    }
  
  
    col= vec3(shad);
    uv.y*=5.;
    if(mat == 1)col =vec3(octaves(uv/10.,8)/1.6)+vec3(.5);
    col = mix(col,vec3(0.),1.-exp(-0.4*shad));//fog
    glFragColor = vec4(col,1.0);
}

#version 420

// original https://www.shadertoy.com/view/Wt3SDj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

int mat = 0;
float epsi = 0.001;

float random(vec2 p){

    vec3 p3  = fract(vec3(p.xyy) * .10031);
    p3 += dot(p3, p3.yyx + 33.33);
    return fract((p3.x + p3.y) );
}
float noise(vec2 uv){

    vec2 id = floor(uv*8.);
    vec2 lc = smoothstep(0.,1.,fract(uv*8.));
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
mat2 rot(float a){
    return mat2(sin(a),-cos(a),cos(a),sin(a));
}
float sdSphere(vec3 p){
    return length(p)-1.;
}
float sdRCyl( vec3 p, float ra, float rb, float h ){
  
  vec2 d = vec2( length(p.xz)-2.0*ra+rb, abs(p.y) - h );
  
  return min(max(d.x,d.y),0.0) + length(max(d,0.0)) - rb;
}
float sdRing(vec3 p,float size,mat2 rotate){
    p.zy*=rotate;
    float or =  sdRCyl(p,size,0.,0.4);
    float ir =  sdRCyl(p,size+0.1,0.,0.3);
    return (max(-or,ir));
}
float sdRing2(vec3 p,float size,mat2 rotate){
    p.xy*=rotate;
    float or =  sdRCyl(p,size,0.,0.4);
    float ir =  sdRCyl(p,size+0.1,0.,0.3);
    return (max(-or,ir));
}

float map(vec3 p){

    float sphere = sdSphere(p);
   
 
    
    float ring = sdRing(p,0.85,rot(time));
    float ring2 = sdRing2(p,0.65,rot(time));
    float ring3 = sdRing(p,1.1,rot(-time));
     //p.y+=(sin(length(p.xz*0.9)-time*3.)*.5);
          float plane = p.y +3.5;
    
    float best = min(min(min(min(sphere,plane),ring),ring2),ring3);
    if(best == sphere){
        mat = 1;
    } else if(best == plane){
        mat = 2;
    } else if(best == ring || best == ring2||best == ring3 ) {
        mat = 3;
    }else{mat = 4;}
    return best;
}
vec3 normal(vec3 p){
    vec2 e = vec2(epsi,0);
    return normalize(vec3(map(p+e.xyy)-map(p-e.xyy),
                        map(p+e.yxy)-map(p-e.yxy),
                        map(p+e.yyx)-map(p-e.yyx)));
}

float tr(vec3 ro,vec3 rd){
    float tot = 0.;
    float dst = 0.;
    for(int i = 0; i< 180; i++){
        dst = map(ro+rd*tot);
        tot+=dst;
        if(dst <epsi||tot>180.)break;
    }
    
    if(dst >epsi){
        mat = 0;
    }
    return tot;
}

void main(void) {
    vec2 uv = (gl_FragCoord.xy-0.5* resolution.xy)/resolution.y;
    vec3 ro = vec3(2,-1.5,-9);
    vec3 rd = normalize(vec3(uv,1));
    ro.zy*=rot(2.1);
    rd.zy*=rot(2.1);
    ro.zx*=rot(time);
    rd.zx*=rot(time);
    vec3 color = vec3(1);
    
    for(int i =0;i<7;i++){
        vec3 p = (ro+rd*tr(ro,rd));
       
      
        if(mat == 0){
        
          
            uv.x+=time/60.;
            uv.x*=0.7;
            color *= vec3(octaves(uv,9)+0.5);
     
            
           
        }if(mat == 1){
         vec3 n = normal(p);
           float fresnel = pow(1.-dot(- rd,n),5.);
            color*= fresnel;
               ro = p+1.;
                rd = reflect(rd,n);
        }
        if(mat == 2){
         vec3 n = normal(p);
            color*= vec3(0.25,0.3,0.3);
              ro = p+1.;
            rd = reflect(rd,n);
        }
        if(mat ==3){
         vec3 n = normal(p);
            color *= vec3(0.9,0.7,0.3);
               ro = p+1.;
        rd = reflect(rd,n);
        }
 
    }

   
    glFragColor = vec4((color),1.0);
}

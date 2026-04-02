#version 420

// original https://www.shadertoy.com/view/Nlf3z8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

int matID = 0;
int scene = 1;

mat2 rotate(float a){
    return mat2(cos(a),-sin(a),sin(a),cos(a));
}

float sdfLP(vec3 p, float norm, float size){
    float px = pow(abs(p.x),norm);
    float py = pow(abs(p.y),norm);
    float pz = pow(abs(p.z),norm);
    return pow(px+py+pz,1./norm)-size;
}

float sdfBox( vec3 p, vec3 b ){
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float map(vec3 p,int id){
    float subject = 999.;
    if(scene ==0){
        vec3 q = p;
        q.x+=sin(q.y+time)*.5;
        vec3 center = floor(q*.2)+.5;
        subject = sdfLP(q-center,(sin(time)*2.)+2.9,.4);
    }else if(scene ==1){
        vec3 q = p;
        subject = sdfLP(q,(sin(time)*2.)+2.9,.9);
    }else if(scene ==2){
        vec3 q = p;
        q.y-=.5;
        q.x+=sin(q.y*10.+time*1.)*.2;
        vec3 center = vec3(floor(q.xz)+.5,0.);
        subject = sdfLP(q-center.xzy,1.,.3);
    } 
    
    float plane = p.y+1.5;
    float cil = 1.5-p.y;
    float box = -sdfBox(p+vec3(0.,0.,0.),vec3(4.,4.,4.));
    float best = min(cil,min(box,min(subject,plane)));
    if(id != 0){
        if(best == subject){matID = 2;}
        if(best == plane){matID=3;}
      
        if(best == box){matID=4;}
        if(best ==cil)matID=5;
    }
    return best;
}
vec3 normal(vec3 p){
    vec2 e= vec2(0,0.001);
    return normalize(vec3(map(p+e.yxx,0)-map(p-e.yxx,0),
                          map(p+e.xyx,0)-map(p-e.xyx,0),
                          map(p+e.xxy,0)-map(p-e.xxy,0)));
}
vec3 march(vec3 ro, vec3 rd){
    float total = 0.;
    float dist = 0.;
    for(int i = 0; i<500; i++){
        dist = map(ro+rd*total,1)*.5;
        total+=dist;
        if(dist < 0.001 || total>500.){
            break;
        }
    }
    if(dist>0.01){
        matID = 1;
    }
   
    return (ro+rd*total);
    
}
void main(void) {
   
    vec2 uv = (gl_FragCoord.xy-0.5*resolution.xy)/resolution.y;
    vec3 ro = vec3(0.);
    vec3 rd = normalize(vec3(uv,1.));
    scene = int(mod(time*.1,3.));
    if(scene == 0){
        ro = vec3(0,0.3,-3.5);
        ro.zy*=rotate(.4);
        rd.zy*=rotate(.4);
        ro.xz*= rotate(time*.1);
        rd.xz*= rotate(time*.1);
    }else if(scene ==1){
        ro = vec3(0,0.8,-2.5);
        rd.zy*=rotate(-.3);
        ro.xz*= rotate(time*.1);
        rd.xz*= rotate(time*.1);
    
    }else if(scene ==2){
        ro = vec3(0,.3,-0.3);
        rd.zy*=rotate(.1);
        rd.zy*=rotate(.1);
        ro.xz*= rotate(time*.1);
        rd.xz*= rotate(time*.1);
    
    }
    
    vec3 accum = vec3(1);
    for(int i = 0; i <9; i++){
        vec3 col =(march(ro,rd));
        vec3 n = normal(col);
        if(matID ==1){
            accum *= vec3(1);
           }    
        if(matID ==2){
            accum *= vec3(.9);
            ro = col*2.;
            rd=normalize(reflect(rd,n));
        }
        if(matID ==3){
            accum *= vec3(0.8);
        }
        if(matID ==4){
            accum *= vec3(0.99,.996,0.99);
            float fresnel = pow(1.-dot(- rd,n),0.03);
            accum*=fresnel;  
            ro = col*.999;
            rd=normalize(reflect(rd,n));
        }
        if(matID ==5){
            accum *= vec3(.999);
        }
    }
    glFragColor = vec4(accum,1.0);
}

#version 420

// original https://www.shadertoy.com/view/WsBcDR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

int matID = 0;

//https://www.shadertoy.com/view/ll2GD3
vec3 pal( in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d ){
    return a + b*cos( 6.28318*(c*t+d) +time);
}
mat2 rotate(float a){
    return mat2(cos(a),-sin(a),sin(a),cos(a));
}

float sdfBox( vec3 p, vec3 b ){
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float sdfSphere(vec3 p,float size){
    return length(p)-size;
}

float sdfCutAwayBox(vec3 translate,mat2 rot){
    translate.xz*= rot;
    float a = 0.5;
    float b = 0.2;
    float height = 4.0;
    
    float a2= length(vec2(a/1.5,b/2.)); 
     
    return sdfBox(translate,vec3(a2,height,b));
}

float sdfPlane(vec3 p){
    return p.y +15.5;
}

float sdfSword(vec3 p){
    vec3 tip = p;
    tip-=vec3(0,2,1.4);
    tip.zy*=rotate((-12.*3.14)/180.);
    vec3 tip2 = p;
    tip2-=vec3(0,2,-1.4);
    tip2.zy*=rotate((12.*3.14)/180.);
    
    vec3 tip3 = p;
    tip3-=vec3(2.5,2,0);
    tip3.xy*=rotate((-24.*3.14)/180.);
    vec3 tip4 = p;
    tip4-=vec3(-2.5,2,0);
    tip4.xy*=rotate((24.*3.14)/180.);
    
    
    float a = 0.5;
    float b = 0.2;
    float height = 4.;
    
    float a2= length(vec2(a/2.,b/2.)); 
    float box = sdfBox(p+vec3(0,-1,0),vec3(a,height,b));
    
    float box2 = sdfCutAwayBox(p+vec3(-0.53,-1,-0.3),rotate((20.*3.14)/180.));
    float box3 = sdfCutAwayBox(p+vec3(-0.53,-1,0.3),rotate((-20.*3.14)/180.));
    
    float box4 = sdfCutAwayBox(p+vec3(0.53,-1,-0.3),rotate((-20.*3.14)/180.));
    float box5 = sdfCutAwayBox(p+vec3(0.53,-1,0.3),rotate((20.*3.14)/180.));
    float box6 = sdfBox(tip,vec3(2,2,1.2));
    float box7 = sdfBox(tip2,vec3(2,2,1.2));
    float box8 = sdfBox(tip3,vec3(2,4,1.2));
    float box9 = sdfBox(tip4,vec3(2,4,1.2));
    
    float crossGuard = sdfBox(p+vec3(0.,3.3,0.),vec3(1.,0.3,0.3));
    float pom = sdfSphere(p+vec3(0,6.4,0),0.4);
    p.xz*=rotate(p.y*8.);
    float handle = sdfBox(p+vec3(0.,4.8,0),vec3(0.2,1.3,0.2));
 
  
    float best = max(min(handle,min(crossGuard,min(pom,box))),
                     -min(box8,min(box6,min(box9,min(box5,min(box4,min(box3,min(box2,box7))))))));
    

    return best;
}

float map(vec3 p){    
    p.x+=sin(time*2.)*1.5;
    float plane = sdfPlane(p);
    float plane2 = sdfPlane(p*vec3(1,-1,1));
  
    float ang = 6.283185/13.0;
    float sector = round(atan(p.x,p.y)/ang);
    float c = 44.;
    vec3 r = mod(p+0.5*c,c)-0.5*c;
    vec3 q = p;
    q.z = r.z;
    
    float an = sector*ang;
    
    q.xy *= rotate(an);
    
    q.zy *=rotate((180.*3.14)/180.);
    vec3 q2 = q;
    q2.zy*=rotate((180.*3.14)/180.);
    
   
    float sword = sdfSword(q+ vec3(0,6,0));
    float sword2 = sdfSword(q2- vec3(0,10,22));
    float best = min(plane,min(plane2,min(sword2,sword)));
    if(best == sword || best == sword2){
        matID=1;
    } else if(best == plane || best == plane2){matID=2;}
    return best;
}

vec3 normal(vec3 p){
    vec2 e= vec2(0,0.01);
    return normalize(vec3(map(p+e.yxx)-map(p-e.yxx),
                          map(p+e.xyx)-map(p-e.xyx),
                          map(p+e.xxy)-map(p-e.xxy)));
}

vec3 march(vec3 ro, vec3 rd){
    float total = 0.;
    float dist = 0.;
    for(int i = 0; i<100; i++){
        dist = map(ro+rd*total);
        total+=dist;
        if(dist < 0.1){
            break;
        }
    }
    
   
    return (ro+rd*total);
    
}

void main(void) {
   
    vec2 uv = (gl_FragCoord.xy-0.5*resolution.xy)/resolution.y;
    vec3 ro = vec3(0,0,time*20.);
    vec3 rd = normalize(vec3(uv,1.));
    vec2 st = uv*5.*sin(time);
    st*=rotate(time);
    st = fract(st);
    
    ro.xy*= rotate(time*.5);
    rd.xy*= rotate(time*.5);
    
   
    vec3 col = (march(ro,rd));
    vec3 p = (march(ro,rd));
    vec3 n = normal(p);
    
      if(matID ==1){
        col = 1.-pal((max(dot(normalize(ro-p),n),0.)),vec3(0.8,0.5,0.4),vec3(0.2,0.4,0.2),vec3(2.0,1.0,1.0),vec3(0.0,0.25,0.25) );
    }
     if(matID ==2){
         col = mix(vec3(0.04,0.14,0.15),vec3(0.04,0.33,0.32),vec3(smoothstep(0.2,0.19,length(st-0.5))));
    }
   
    glFragColor = vec4(col,1.0);
}

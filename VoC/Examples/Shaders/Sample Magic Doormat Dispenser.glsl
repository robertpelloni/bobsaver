#version 420

// original https://www.shadertoy.com/view/stjSWh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define STEPS 128.0
#define MDIST 40.0
#define pi 3.1415926535
#define pmod(p,x) (mod(p,x)-0.5*(x))
#define rot(a) mat2(cos(a),sin(a),-sin(a),cos(a));

//box sdf
float box(vec3 p, vec3 s){
    vec3 d = abs(p)-s;
    return max(d.x,max(d.y,d.z));
}
//iq's color palette function
vec3 pal( in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d ){
    return a + b*cos( 6.28318*(c*t+d) );
}
//An interpolated sinwave with variable sample rate to give the carpets a low poly look
float psin(float x, float b){
    return sin(floor(b*x)/b)+(sin(floor(b*x+1.0)/b)-sin(floor(b*x)/b))*mod(b*x,1.0);
}

vec3 map(vec3 p){
    vec3 a = vec3(0);
    
    float t = mod(time,9999.0);
    
    //scroll the y axis up all the time 
    p.y-=t-0.25;
    
    //id of y axis domain repition
    float id = floor(p.y/1.0)+0.5;
    
    //x value to offset carpets so they fly left and right
    float xoff =max(0.0,(id+t)*2.0);
    xoff = xoff*xoff*sign(sin(id*pi));;
    
    //domain repition in the y axis
    p.y = pmod(p.y,1.0);

    //Add some low poly waves to the carpets
    float sb = .7;
    float wscl = 0.06;
    p.y+=psin(p.x*4.0+id,sb)*wscl;
    p.y-=psin(p.z*4.0+id,sb)*wscl;

    //calculate box sdf
    a.x = box(p-vec3(xoff,0,0),vec3(2,0.025,2));
    
    //pass some info to coloring code
    a.y = id;
    a.z = xoff;
    
    return a;
}

vec3 norm(vec3 p){
    vec2 e = vec2(0.01,0);
    return normalize(map(p).x-vec3(
    map(p-e.xyy).x,
    map(p-e.yxy).x,
    map(p-e.yyx).x));
}
//mirror function
void mo(inout vec2 p){
  if(p.y>p.x) p = p.yx;
}
vec2 kifs(vec2 uv,float id){
    //some kifs and abs() duplication code
    for(float i = 0.0; i< 9.0; i++){
        uv = abs(uv)-0.7*i*(vec2((sin(id*0.15)),0.2*(cos(id*0.22))));
        //Adjusting this rotation value gives some cool alternate designs
        uv*=rot(pi/(2.0));
        mo(uv);
    }
    uv = abs(uv)-0.5;
    uv = abs(uv)-0.5;
    uv = abs(uv)-0.5;
    return uv;
}
float getRug(vec2 uv, float id){
    vec3 col = vec3(0);
    float a =0.0;
    
    //sometimes the result of the kifs will not give any pattern on the carpet
    //to fix this I run the kifs 8 times with different initial conditions and xor
    //all the patterns so you can't really tell when there are gaps.
    //someone who is better at kifs could probably just fix the problem
    
    for(float i = 0.0; i <8.0; i++){
        a = mix(a,1.0-a,smoothstep(0.21,0.19,box(vec3(kifs(uv,id+i*pi),0),vec3(0.2)))); 
    }
    return float(a);
}
//radial mod (stole a flopine shader)
vec2 moda (vec2 p, float per)
{
    float a = atan(p.y,p.x);
    float l = length(p);
    a = mod(a-per/2.,per)-per/2.;
    return vec2 (cos(a),sin(a))*l;
}
void main(void)
{
    vec2 uv = (gl_FragCoord.xy-0.5*resolution.xy)/resolution.y;
    vec3 col = vec3(0);
    float t = time;
    float aa = 1.0/resolution.y;
    vec3 ro = vec3(0,3,-7);
    vec3 rd = normalize(vec3(uv,1.0));
    rd.yz*=rot(-0.4 );
    vec3 p = ro;
    vec3 d;
    bool hit = false;
    float dO;
    //raymarch loop
    for(float i = 0.0; i<STEPS; i++){
        d = map(p);
        dO+=min(0.75,d.x*0.8);
        p = ro+rd*dO;
        
        if(abs(d.x)<0.001){
            hit = true;
            break;
        }
        if(dO>MDIST){break;}
    }
    
    //if ray marcher hits something color it
    if(hit){ 
        vec3 palc = 0.9*pal(d.y/3.0, vec3(0.3),vec3(0.5),vec3(1.7),vec3(0,0.33,0.66) );
        float bright = mix(1.,1.,sin(d.y*pi)*0.5+0.5);
        vec3 al = mix(palc,vec3(bright),getRug(vec2(p.x-d.z,p.z),d.y));

        vec3 n = norm(p);
        vec3 ld = normalize(vec3(0.2,1,1));
        vec3 h = normalize(ld-rd);
        float spec = pow(max(dot(n,h),0.0),20.0);
        float fres = pow(1. - max(dot(n, -rd),0.), 5.);
        float diff = max(dot(n, ld),0.);
        

        //some hacky soft shadows
        float shadow = 1.0;
        float md = 1.0;
        vec3 sp = p + n * 0.5;
        for(int i=0; i<10; ++i) {
        
          float d=map(sp).x;
          
          if(d>3.0) break; 
          sp+=min(d,0.4)*ld;
          md = min(md, d);
          if(md<0.5) shadow = md+0.5;
          
        }
        //I still have no idea what I am doing with these lighting mixes
        shadow = pow(shadow,1.75);
        col = al;
        col+=spec*0.3*shadow*vec3(1.000,0.831,0.439);
        col+=fres*0.175*shadow*vec3(1.000,0.957,0.824);
        col*=clamp(diff*vec3(1.000,0.957,0.824),0.2,1.0);
        col*=clamp(shadow,0.0,1.0);
    }
    //if ray marcher didn't hit then render the background
    else{
        vec2 uvo = uv;
        uv.y-=0.5;
        uv.x-=0.7;

        //orange/purple gradient
        col = mix(vec3(0.976,0.502,0.243),vec3(0.420,0.259,1.000),min(length(uv)-0.4,1.2));

        //big sun circle
        float sun =smoothstep(length(uv)-aa,length(uv)+aa,0.3);
        uv*=rot((floor(length(uv)/0.1)+0.5)-t*0.025);

        //lots of little tiny rings
        uv = moda(uv,0.3);
        uv.x = pmod(uv.x,0.1);
        float rs = 0.035/2.0;
        sun += (smoothstep(length(uv)-aa,length(uv)+aa,rs)
        -smoothstep(length(uv)-aa,length(uv)+aa,rs*0.5));
        col+=min(sun,1.0);
        
        //Some sand dune thingys
        uv = uvo;
        uv.y+=sin(uv.x*12.0-t*0.4+5.0)*0.015;
        col=mix(col,vec3(1.000,0.655,0.275),smoothstep(uv.y-aa,uv.y+aa,-0.25));
        uv = uvo;
        uv.y+=sin(uv.x*12.0-t+2.5)*0.015;
        col=mix(col,vec3(0.957,0.584,0.357),smoothstep(uv.y-aa,uv.y+aa,-0.325));
        uv = uvo;
        uv.y+=sin(uv.x*12.0-t*1.8)*0.015;
        col=mix(col,vec3(0.894,0.871,0.353),smoothstep(uv.y-aa,uv.y+aa,-0.4));
        
    }
    //Gamma
    col =sqrt(col);
    
    glFragColor = vec4(col,1.0);
}

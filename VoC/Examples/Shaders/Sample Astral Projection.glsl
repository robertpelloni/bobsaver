#version 420

// original https://www.shadertoy.com/view/WtKSWD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float distLine(vec2 p, vec2 a, vec2 b) {
    vec2 pa = p-a;
    vec2 ba = b-a;
    float t = clamp(dot(pa,ba)/dot(ba,ba),0.,1.);
    return length(pa-ba*t);
}
float line(vec2 p, vec2 a, vec2 b){
float d = distLine(p,a,b);
float m =smoothstep(0.04,0.007,distLine(p,a,b));

float d2 = length(a-b);
  m *= smoothstep(0.6- .1/(length(p)), .3 , d2)*.2 + smoothstep(.0122,.00121,abs(d2-.75)) ;//* (.25/length((p-a)+(p-b)));
  return m;
}
float n21(vec2 p){
  p = fract(p*vec2(123.213,853.4264));
  p += dot(p,p+6.65);
  return fract(p.x*p.y);

}
vec2 n22(vec2 p){
    float n = n21(p);
    return vec2(n, n21(p+n));
}

vec2 getPos(vec2 id, vec2 offset) {
    vec2 n = n22(id+offset)*time;
    return offset+sin(n)*.4;
}
mat2 r(float a){
    float c=cos(a), s=sin(a);
    return mat2(c,-s,s,c);
}
float layer(vec2 uv){

    float m = 0.;
    vec2 gv = fract(uv)-.5;
    vec2 id = floor(uv);

    vec2 gridPos[9];
    int ppos = 0;
    for(int y = -1; y<=1; y++) {
        for(int x = -1; x<=1; x++) {
            gridPos[ppos++] = getPos(id,vec2(x,y));
            
           
        }
    }
    for(int i=0;i<9;i++){
        m+=line(gv,gridPos[4],gridPos[i]);
        
        vec2 jj = (gridPos[i] - gv)*12.;
        float sparkle = 1./length(dot(jj,jj));
        m+=sparkle*(sin(time+ fract(gridPos[i].x) *10.)*.5+.5);
    }
     m+=line(gv,gridPos[1],gridPos[3]);
     m+=line(gv,gridPos[1],gridPos[5]);
     m+=line(gv,gridPos[7],gridPos[3]);
     m+=line(gv,gridPos[7],gridPos[5]);
     return m ;
}
#define ttime floor(time*.5) + pow(fract(time*.5),.5)
void main(void)
{
    
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy) / resolution.y;
    vec2 mouse = (mouse*resolution.xy.xy / resolution.xy) -.5;
 
      
     float m = 0.;
      //uv*=exp(length(uv)*.2);
      uv*=.75;
      uv*=r(atan(uv.x,uv.y)*2.*1.5);
      uv*=r(cos(length(uv)*3.1415));
      uv*=r(-time*.1);
      uv=-abs(uv);

     uv*=2.;
  
      //uv.x+=-time*.0001;   
      float t = time*.0025;
    
      vec3 col = vec3(0.);
     for( float i=0.; i<1.; i+= (1./5.) ) {
          float z = fract(i+t);
  
          float size = mix(8.+sin(i*3.1415*(sin(time)*.5+1.5)+ttime)*8.,2.,z);
          float fade = smoothstep(.0,.4,z) * smoothstep(1.,.6,z);
         uv*=r(t*sin(i*10.));
                             
          m += layer(uv*size+i*20.) * fade ;
          vec3 base = mix(vec3(.75+sin(ttime+length(uv*4.))*.1,.2,.6),vec3(.1,.2,.6),vec3(sin(i*4.5)*.5+.5,0.+m*1.,i*2.));
          col += vec3(m)*base;
     }
 

    //if(gv.x>.47 || gv.y >.47) col.r = 1.;
    glFragColor = vec4(col,1.0);
   
}

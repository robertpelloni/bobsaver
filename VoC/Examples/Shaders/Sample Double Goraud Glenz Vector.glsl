#version 420

// original https://www.shadertoy.com/view/NtcfRj

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float zcur = 0.0;

vec2 InsideTrian(float x1, float y1, float z1, float x2, float y2, float z2, float x3, float y3, float z3, float xp, float yp) {

 float tmp;
 float curz;
 
 
 if (y1>y3) {
  tmp=y3;
  y3=y1;
  y1=tmp;
   
  tmp=x3;
  x3=x1;
  x1=tmp;
  
  tmp=z3;
  z3=z1;
  z1=tmp; 
   
  }
  
  if (y1>y2) {
  tmp=y2;
  y2=y1;
  y1=tmp;
   
  tmp=x2;
  x2=x1;
  x1=tmp;
  
  tmp=z2;
  z2=z1;
  z1=tmp; 
  
  } 
    
  if (y2>y3) {
  tmp=y2;
  y2=y3;
  y3=tmp;
  
  tmp=x2;
  x2=x3;
  x3=tmp;
  
  tmp=z2;
  z2=z3;
  z3=tmp; 
  }
  
  if ((yp<y1)||(yp>y3)) return vec2(0.0,0.0);

// yp is beetween y1 a y3

 float       xw1 = x1+((x3-x1)/(y3-y1))*(yp-y1);
 float       dz1 = z1+((z3-z1)/(y3-y1))*(yp-y1);
 
 float xw2,dz2;

 if (yp>y2)  { xw2 = x2+((x3-x2)/(y3-y2))*(yp-y2);
               dz2 = z2+((z3-z2)/(y3-y2))*(yp-y2);
             }
 
 else        { xw2 = x1+((x2-x1)/(y2-y1))*(yp-y1);
               dz2 = z1+((z2-z1)/(y2-y1))*(yp-y1);
             }
 
 curz = dz1 + (dz2-dz1)/(xw2-xw1)*(xp-xw1);
  
 return vec2(float(((xw1<=xw2) && (xw1<=xp)&&(xw2>=xp))||((xw1>xw2) && (xw2<=xp)&&(xw1>=xp))),curz); 
 }

vec3 rotateX(float angle, float x, float y, float z)
{
    float c = cos(angle);
    float s = sin(angle);
    return vec3(x,(s*z-c*y),(s*y+z*c));
}

vec3 rotateY(float angle, float x, float y, float z)
{
    float c = cos(angle);
    float s = sin(angle);
    return vec3((s*z+c*x),y,(s*x-z*c));
}

vec3 rotateZ(float angle, float x, float y, float z)
{
    float c = cos(angle);
    float s = sin(angle);
    return vec3((x*s+y*c),(s*y-c*x),z);
}

void main(void)
{

 vec2 calculatedvertex[30];
 vec3 verttable[15];
 float ztable[30];
 

 verttable[0] = vec3(-1.0,-1.0,1.0);
 verttable[1] = vec3(1.0,-1.0,1.0);
 verttable[2] = vec3(1.0,1.0,1.0);
 verttable[3] = vec3(-1.0,1.0,1.0);

 verttable[4] = vec3(-1.0,-1.0,-1.0);
 verttable[5] = vec3(1.0,-1.0,-1.0);
 verttable[6] = vec3(1.0,1.0,-1.0);
 verttable[7] = vec3(-1.0,1.0,-1.0);

 verttable[8] = vec3(0.0,0.0,1.0);
 verttable[9] = vec3(0.0,0.0,-1.0);
 verttable[10] = vec3(1.0,0.0,0.0);
 verttable[11] = vec3(-1.0,0.0,0.0);
 verttable[12] = vec3(0.0,-1.0,0.0);
 verttable[13] = vec3(0.0,1.0,0.0);
 
int sk1[24] = int[24] (
  4,5,4,0,
  6,7,6,2,
  0,7,4,7,
  1,5,5,6,
  0,2,2,0,
  4,6,6,4); 
 
int sk2[24] = int[24] (
  0,1,5,1,
  2,3,7,3,
  3,4,0,3,
  2,6,1,2,
  1,3,1,3,
  5,7,5,7);
 
int sk3[24] = int[24] (
 12,12,12,12,
 13,13,13,13,
 11,11,11,11,
 10,10,10,10,
 8,8,8,8,
 9,9,9,9);

 // Normalized pixel coordinates (from 0 to 1)
 
  vec2 uv = gl_FragCoord.xy/resolution.xy-0.5;

  uv.x*= resolution.x/resolution.y;

 //  uv.x = floor(uv.x *160.)/160.;
 //  uv.y=  floor(uv.y *113.)/113.;

//    uv.x = floor(uv.x *80.)/80.;
//    uv.y=  floor(uv.y *56.)/56.;

  float d=0.9; // distance
  float squaresize = 0.8;
  float halfsquare = squaresize/2.;
  
  float Realtime = float(frames);
  
  //Realtime = Realtime + uv.y*19.; //+uv.x*10.;
  
  float angleX = Realtime*0.018;
  float angleY = Realtime*-0.037;
  float angleZ = Realtime*0.01;
  
  
  vec3 col = vec3(0.0,0.0,0.0);
  vec3 triancol;

  float addx = sin(time*2.1)*0.35;
  float addy = sin(-time*3.0)*0.062;

 float Zdistance = 0.48-sin(time*1.4)*0.65-cos(time*2.3)*0.65;
 
 float mixfactor =smoothstep(0.0,1.0,clamp(length(vec2(uv.x+addx,uv.y+addy))*2.2-0.7,0.0,1.0));
 
 
 if (Zdistance>=0.2) Zdistance = mix(0.2,Zdistance,mixfactor);
 
 
 float x = uv.x+uv.x/((1.+Zdistance/d)*squaresize);
 float y = uv.y+uv.y /((1.+Zdistance/d)*squaresize);

 
 float a= mod (addx+x , squaresize);
 float b= mod (addy+y, squaresize);
 
 float halfsquarex = squaresize/2.;
 float halfsquarey = squaresize/2.;
 

 if ((a<=halfsquarex) && (b<=halfsquarey) || (a>=halfsquarex) && (b>=halfsquarey)){
 col = vec3(0.0,1.0,0.0)*clamp(Zdistance+0.15,0.1,1.1);
 }
 else col = vec3(0.17,0.17,0.17)*clamp(Zdistance+0.05,0.0,1.1); 

// rotate & perspective calc

 float scale = 0.24;

 for (int rep=0 ; rep<=1 ; ++rep){

    for (int licz=0 ; licz<=13 ; ++licz){

    vec3 rotxyz = verttable[licz]*scale;
 
    rotxyz = rotateX(angleX,rotxyz.x,rotxyz.y,rotxyz.z);
    rotxyz = rotateY(angleY,rotxyz.x,rotxyz.y,rotxyz.z);
    rotxyz = rotateZ(angleZ,rotxyz.x,rotxyz.y,rotxyz.z);

    rotxyz.x = rotxyz.x/(1.+rotxyz.z/d);
    rotxyz.y = rotxyz.y/(1.+rotxyz.z/d);

    calculatedvertex[licz+14*rep]=0.0-vec2(addx+rotxyz.x,addy+rotxyz.y);
    ztable[licz+14*rep] = rotxyz.z;

  }
   scale = scale-0.09;
   
   angleX = angleX+sin(time*1.2)*0.4;
   
   angleY = angleY-sin(time*2.2)*0.4;
   angleZ = angleZ-sin(time*2.9)*0.4;
   
 }
 
 
 
vec2 trn;

// draw back vector part

 for (int face=0 ; face<=23 ; ++face){
 
   if (ztable[sk3[face]]>-0.072) {
   vec2 pos1 = calculatedvertex[sk1[face]];
   vec2 pos2 = calculatedvertex[sk2[face]];
   vec2 pos3 = calculatedvertex[sk3[face]];
  
   trn = (InsideTrian(pos1.x,pos1.y,ztable[sk1[face]],pos2.x,pos2.y,ztable[sk2[face]],pos3.x,pos3.y,ztable[sk3[face]], uv.x , uv.y));
  
   if  (trn.x==1.) { 
   
   if ((face&0x2)==0) col=vec3(0.1,0.15,1.0)*(0.8-trn.y); 
   else col=vec3(0.0,0.1,0.6)*(0.8-trn.y);
   
   }
  }
 }  
 
float zpoint = 0.029;  
 
 for (int face=0 ; face<=23 ; ++face){
 
   if (ztable[sk3[face]+14]>-zpoint) {
   vec2 pos1 = calculatedvertex[sk1[face]+14];
   vec2 pos2 = calculatedvertex[sk2[face]+14];
   vec2 pos3 = calculatedvertex[sk3[face]+14];
  
   trn = (InsideTrian(pos1.x,pos1.y,ztable[sk1[face]+14],pos2.x,pos2.y,ztable[sk2[face]+14],pos3.x,pos3.y,ztable[sk3[face]+14], uv.x , uv.y));
  
   if  (trn.x==1.) { 
   
   if ((face&0x2)==0) col=vec3(1.0,0.15,0.1)*(0.8-trn.y); 
   else col=vec3(0.6,0.1,0.0)*(0.8-trn.y);
   
   }
  }
 } 

// draw front vector part
 
 triancol=vec3(1.0,1.0,1.0);
 
 for (int face=0 ; face<=23 ; ++face){
 
   if (ztable[sk3[face]+14]<-zpoint) {
   vec2 pos1 = calculatedvertex[sk1[face]+14];
   vec2 pos2 = calculatedvertex[sk2[face]+14];
   vec2 pos3 = calculatedvertex[sk3[face]+14];
  trn = (InsideTrian(pos1.x,pos1.y,ztable[sk1[face]+14],pos2.x,pos2.y,ztable[sk2[face]+14],pos3.x,pos3.y,ztable[sk3[face]+14], uv.x , uv.y));
  
   if ((trn.x==1.)&&(face&0x2)==0) col = vec3(0.22-trn.y)*1.9 ; //triancol;
   }
 }  
 
 
 
 
 
 
 for (int face=0 ; face<=23 ; ++face){
 
   if (ztable[sk3[face]]<-0.072) {
   vec2 pos1 = calculatedvertex[sk1[face]];
   vec2 pos2 = calculatedvertex[sk2[face]];
   vec2 pos3 = calculatedvertex[sk3[face]];
  trn = (InsideTrian(pos1.x,pos1.y,ztable[sk1[face]],pos2.x,pos2.y,ztable[sk2[face]],pos3.x,pos3.y,ztable[sk3[face]], uv.x , uv.y));
  
  if ((trn.x==1.)&&(face&0x2)==0) col = vec3(0.22-trn.y)*1.9 ; //triancol;
   }
 } 

    // Output to screen
    glFragColor = vec4(col,1.0);
}


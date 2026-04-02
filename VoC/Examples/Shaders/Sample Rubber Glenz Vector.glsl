#version 420

// original https://www.shadertoy.com/view/sl3fz4

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

bool InsideTrian(float x1, float y1, float x2, float y2, float x3, float y3, float xp, float yp) {

 float tmp;
 
 if (y1>y3) {
  tmp=y3;
  y3=y1;
  y1=tmp;
   
  tmp=x3;
  x3=x1;
  x1=tmp;
  }
  
  if (y1>y2) {
  tmp=y2;
  y2=y1;
  y1=tmp;
   
  tmp=x2;
  x2=x1;
  x1=tmp;
  } 
    
  if (y2>y3) {
  tmp=y2;
  y2=y3;
  y3=tmp;
  
  tmp=x2;
  x2=x3;
  x3=tmp;
  }
  
  if ((yp<y1)||(yp>y3)) return false;

// yp is beetween y1 a y3

 float xw1 = x1+((x3-x1)/(y3-y1))*(yp-y1);
 float xw2;

 if (yp>y2) {

 xw2 = x2+((x3-x2)/(y3-y2))*(yp-y2);
 }
 else{
   
 xw2 = x1+((x2-x1)/(y2-y1))*(yp-y1);
 }
 
 return (((xw1<=xw2)&& (xw1<=xp)&&(xw2>=xp))||((xw1>xw2) && (xw2<=xp)&&(xw1>=xp))); 
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

 vec2 calculatedvertex[15];
 vec3 verttable[15];
 float ztable[15];
 

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

  float d=0.9; // distance
  float squaresize = 0.60;
  float halfsquare = squaresize/2.;
  
  float Realtime = float(frames);
  
  Realtime = Realtime + uv.y*29.; //+uv.x*10.;
  
  float angleX = Realtime*0.018;
  float angleY = Realtime*-0.037;
  float angleZ = Realtime*0.01;
  
  
  vec3 col = vec3(0.0,0.0,0.0);
  vec3 triancol;

  float addx = sin(time*2.1)*0.07;
  float addy = sin(-time*3.0)*0.062;

// draw cheesboard
 
 float a= mod (addx+uv.x+0.45 , squaresize);
 float b= mod (addy+uv.y-0.15, squaresize);

 if ((a<=halfsquare) && (b<=halfsquare) || (a>=halfsquare) && (b>=halfsquare)) col = vec3(0.0,0.55,0.0);

// rotate & perspective calc

 for (int licz=0 ; licz<=13 ; ++licz){

 vec3 rotxyz = verttable[licz]*0.23;
 
 rotxyz = rotateX(angleX,rotxyz.x,rotxyz.y,rotxyz.z);
 rotxyz = rotateY(angleY,rotxyz.x,rotxyz.y,rotxyz.z);
 rotxyz = rotateZ(angleZ,rotxyz.x,rotxyz.y,rotxyz.z);

 rotxyz.x = rotxyz.x/(1.+rotxyz.z/d);
 rotxyz.y = rotxyz.y/(1.+rotxyz.z/d);

 calculatedvertex[licz]=vec2(addx+rotxyz.x,addy+rotxyz.y);
 ztable[licz] = rotxyz.z;

 }
 
// draw back vector part
 
 for (int face=0 ; face<=23 ; ++face){
 
   if (ztable[sk3[face]]>-0.072) {
   vec2 pos1 = 0.0-calculatedvertex[sk1[face]];
   vec2 pos2 = 0.0-calculatedvertex[sk2[face]];
   vec2 pos3 = 0.0-calculatedvertex[sk3[face]];
  
   if (InsideTrian(pos1.x,pos1.y,pos2.x,pos2.y,pos3.x,pos3.y, uv.x , uv.y)) { 
   
   if ((face&0x2)==0) col=vec3(0.1,0.15,1.0);
   else col=vec3(0.0,0.1,0.6);
   
   }
  }
 } 
 
// draw front vector part
 
 triancol=vec3(1.0,1.0,1.0);
 
 for (int face=0 ; face<=23 ; ++face){
 
   if (ztable[sk3[face]]<-0.072) {
   vec2 pos1 = 0.0-calculatedvertex[sk1[face]];
   vec2 pos2 = 0.0-calculatedvertex[sk2[face]];
   vec2 pos3 = 0.0-calculatedvertex[sk3[face]];
  
   if ((InsideTrian(pos1.x,pos1.y,pos2.x,pos2.y,pos3.x,pos3.y, uv.x , uv.y)&&(face&0x2)==0)) col = triancol;
   }
 } 

    // Output to screen
    glFragColor = vec4(col,1.0);
}


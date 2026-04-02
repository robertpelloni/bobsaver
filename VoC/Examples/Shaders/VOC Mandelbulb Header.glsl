//Visions Of Chaos - Mandelbulb mode header

#version 420


uniform vec2 resolution;
uniform vec3 palette[256];
uniform sampler2D zbuffer;
uniform sampler2D backbuffer;

//bulb specific uniforms set from voc
uniform vec3 eye;
uniform vec3 lookat;
uniform vec3 up;
uniform float fov;
uniform float epsilon;
uniform int samplepixels;
uniform vec3 lightpositions[7];
uniform vec3 lightcolors[7];
uniform float lightintensities[7];
uniform int lightsenabled[7]; //0=off 1=on
uniform int shadows; //0=off 1=on
uniform float shadowintensity;
uniform float xrot,yrot,zrot;
uniform vec4 backgroundcolor;
uniform int maxiterations;
uniform float descalefactor;
uniform float power;
uniform float bailout,ambient;
uniform int ambientocclusion; //0=off 1=on
uniform float minorbit,maxorbit;
uniform int juliamode; //0=off 1=on
uniform int specon; //0=off 1=on
uniform float specamount;
uniform vec3 julia;
uniform int formula,formulavariation,shadingstyle;
uniform float thetascale,phiscale,phase;
uniform int spikes; //0=off 1=on
uniform float ymaximum;
uniform float gamma,contrast;
//KIFS uniforms
uniform int boxfolding; //0=off 1=on
uniform int absfolding; //0=off 1=on
uniform int spherefolding; //0=off 1=on
uniform int kzwrap; //0=off 1=on
uniform int krotatearoundorigin; //0=off 1=on
uniform int kprerotate; //0=off 1=on
uniform int normalizekc; //0=off 1=on
uniform float minboxfold,maxboxfold,minspherefold,maxspherefold;
uniform float kr1x,kr1y,kr1z,kr2x,kr2y,kr2z; //rotations
uniform float kcxuniform,kcyuniform,kczuniform; //ceneter of stretch
uniform int kfold; //folding style
//glow
uniform int gloweffect; //0=off 1=on
uniform int outsideglow; //0=off 1=on
uniform int glowthreshold;
uniform vec4 glowcolor;

out vec4 glFragColor;

//internal global variables
float pi=3.14159265;
float pidiv180=0.01745329;
float bailoutsquared,bailouttest;
vec3 roteye,lastz,zpnew;
float del,dr,radius,eps,lastde,zr,shadowfactor;
vec4 thiscolor,finalcol;
int superx,supery,desteps,i,numlights,itercount;
vec3 Z,C,ztta;
float smallestorbit;
float dist;
float theta,phi,rcosphi,sinphi,cosphi,costheta,sintheta;
int firstiteration; //0=no 1=yes

//KIFS variables
float kcx,kcy,kcz; //ceneter of stretch
float DEfactor;
float in3,kphi,salpha,sbeta,stheta,s1,s2,s3,c1,c2,c3,mag;
mat3 rotmat1,rotmat2;
float ftris[3];
float ftria[3];
float ftric[3];
float n3[3];
float x1,y1,z1;

void Rotate2(in float Rx, in float Ry, in float Rz, in float x, in float y, in float z, out float Nx, out float Ny, out float Nz) {
	float TempX,TempY,TempZ,SinX,SinY,SinZ,CosX,CosY,CosZ,XRadAng,YRadAng,ZRadAng;
	XRadAng=Rx*pidiv180;
	YRadAng=Ry*pidiv180;
	ZRadAng=Rz*pidiv180;
	SinX=sin(XRadAng);
	SinY=sin(YRadAng);
	SinZ=sin(ZRadAng);
	CosX=cos(XRadAng);
	CosY=cos(YRadAng);
	CosZ=cos(ZRadAng);
	TempY=y*CosY-z*SinY;
	TempZ=y*SinY+z*CosY;
	TempX=x*CosX-TempZ*SinX;
	Nz=x*SinX+TempZ*CosX;
	Nx=TempX*CosZ-TempY*SinZ;
	Ny=TempX*SinZ+TempY*CosZ;
}

void Rotate(in float Rx, in float Ry, in float Rz, in float x, in float y, in float z, in float ox, in float oy, in float oz, out float Nx, out float Ny, out float Nz){
	Rotate2(Rx,Ry,Rz,x-ox,y-oy,z-oz,Nx,Ny,Nz);
	Nx=Nx+ox;
	Ny=Ny+oy;
	Nz=Nz+oz;
}

//specific iteration code after this line


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
const int maxiterations=7;
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

void Iterate(inout vec3 z,in vec3 c) {
	if (firstiteration==1) {
		theta=atan(z.y,z.x)*thetascale;
		phi=(asin(z.z/radius)+phase)*phiscale;
	} else {
		theta=atan(z.y,z.x);
		phi=asin(z.z/radius)+phase;
	}
	radius=pow(radius,power);
	theta=theta*power;
	phi=phi*power;
	rcosphi=radius*cos(phi);
	z.x=rcosphi*cos(theta)+c.x;
	z.y=rcosphi*sin(theta)+c.y;
	z.z=radius*sin(phi)+c.z;
}

//specific formula iteration code above this line

void IterateFormula(inout vec3 z, in vec3 c) {
	float scale,fixedradius,minradius,fr2,mr2,r2,fr2divmr2,fr2divr2;
	
	radius=length(z);
	if (radius==0.0) {radius=0.00001;}
	zr=pow(radius,power-1.0);
	if (radius<smallestorbit) { smallestorbit=radius; }
	if (radius>bailout) { return; }
	
	Iterate(z,c);
    	
	if (boxfolding==1) {
        if (absfolding==1) {
            if (z.x<-minboxfold) { z.x=-maxboxfold-z.x; }
            if (z.y<-minboxfold) { z.y=-maxboxfold-z.y; }
            if (z.z<-minboxfold) { z.z=-maxboxfold-z.z; }
		} else {
            if (z.x>minboxfold) { z.x=maxboxfold-z.x; } else { if (z.x<-minboxfold) { z.x=-maxboxfold-z.x; } }
            if (z.y>minboxfold) { z.y=maxboxfold-z.y; } else { if (z.y<-minboxfold) { z.y=-maxboxfold-z.y; } }
            if (z.z>minboxfold) { z.z=maxboxfold-z.z; } else { if (z.z<-minboxfold) { z.z=-maxboxfold-z.z; } }
        }
    }

    if (spherefolding==1) {
        fixedradius=maxspherefold;
        fr2=fixedradius*fixedradius;
        minradius=minspherefold;
        mr2=minradius*minradius;
        r2=z.x*z.x+z.y*z.y+z.z*z.z;
        if (r2<mr2) {
            fr2divmr2=fr2/mr2;
            z.x=z.x*fr2divmr2;
            z.y=z.y*fr2divmr2;
            z.z=z.z*fr2divmr2;
            DEfactor=DEfactor*fr2divmr2;
        } else {
			if (r2 < fr2) {
				fr2divr2=fr2/r2;
				z.x=z.x*fr2divr2;
				z.y=z.y*fr2divr2;
				z.z=z.z*fr2divr2;
				DEfactor=DEfactor*fr2divr2;
			}
		}
    }
	
}

float FindDistance(inout vec3 rO, in vec3 rD) {
	int maxsteps;
    eps=epsilon;
    desteps=0;
	maxsteps=0;
    
	while (maxsteps<4000) { //VERY important to avoid endless loops that hang GPU
	//while (1<2) { //endless loop
		maxsteps+=1;;
		//z inialised to ray origin
		Z=rO;
        //lastz initialised to z
        lastz=Z;
        if (juliamode==1) { C=julia; } else { C=Z; }
        //for scalar derivative distance estimation
        dr=1.0;
        DEfactor=1.0;
        //keep track of last distance returned from DE calcs
        lastde=10000000.0;
		smallestorbit=1000.0;
		
		for(i=0; i<maxiterations; i++)
		{
			if (i==0) { firstiteration=1; } else { firstiteration=0; }
			itercount=i;
			IterateFormula(Z,C);
			
			//http://www.fractalforums.com/mandelbulb-implementation/realtime-renderingoptimisations/
			//dr=zr*dr*power+1.0;
			//slower version - kept here for compatibility with voc
			dr=radius*dr*power+1.0;
			
			// mermelada's tweak
			// http://www.fractalforums.com/new-theories-and-research/error-estimation-of-distance-estimators/msg102670/?topicseen#msg102670
			//float DerivativeBias=2.0;
			//dr = max(dr*DerivativeBias,zr*dr*Power + 1.0);

			
			radius=length(Z);
			if (radius>bailout) {break;}
			
			//spikes
			Z.y=min(Z.y,ymaximum);
        }
        
		dist=log(radius)*radius/dr;
		dist=dist*descalefactor;
		rO=rO+rD*dist;
		
        //glow
        desteps+=1;
		desteps=min(desteps,glowthreshold);
		
        bailouttest=rO.x*rO.x+rO.y*rO.y+rO.z*rO.z;
		if (dist<eps) { break; }
		if (bailouttest>bailoutsquared) { break; }
	
     }
     return dist;
}

vec3 EstimateNormal(in vec3 point) {
	vec3 gx1,gy1,gz1,gx2,gy2,gz2,grad,N,cnew;
	int i;
		
	gx1.x=point.x-del; gx1.y=point.y; gx1.z=point.z;
    gx2.x=point.x+del; gx2.y=point.y; gx2.z=point.z;
    gy1.x=point.x; gy1.y=point.y-del; gy1.z=point.z;
    gy2.x=point.x; gy2.y=point.y+del; gy2.z=point.z;
    gz1.x=point.x; gz1.y=point.y; gz1.z=point.z-del;
    gz2.x=point.x; gz2.y=point.y; gz2.z=point.z+del;
	
    if (juliamode>0) { cnew=julia; } else { cnew=gx1; }
	lastz=gx1;
	for(i=0; i<maxiterations; i++)
	{
		if (i==0) { firstiteration=1; } else { firstiteration=0; }
		itercount=i;
		IterateFormula(gx1,cnew);

			Z=gx1;
            radius=Z.x*Z.x+Z.y*Z.y+Z.z*Z.z;
			if (radius>bailoutsquared) { break; }
		//spikes
		Z.y=min(Z.y,ymaximum);
	}

    if (juliamode>0) { cnew=julia; } else { cnew=gx2; }
	lastz=gx2;
	for(i=0; i<maxiterations; i++)
	{
		if (i==0) { firstiteration=1; } else { firstiteration=0; }
		itercount=i;
		IterateFormula(gx2,cnew);

			Z=gx2;
            radius=Z.x*Z.x+Z.y*Z.y+Z.z*Z.z;
			if (radius>bailoutsquared) { break; }
		//spikes
		Z.y=min(Z.y,ymaximum);
	}

	if (juliamode>0) { cnew=julia; } else { cnew=gy1; }
	lastz=gy1;
	for(i=0; i<maxiterations; i++)
	{
		if (i==0) { firstiteration=1; } else { firstiteration=0; }
		itercount=i;
		IterateFormula(gy1,cnew);

			Z=gy1;
            radius=Z.x*Z.x+Z.y*Z.y+Z.z*Z.z;
			if (radius>bailoutsquared) { break; }
		//spikes
		Z.y=min(Z.y,ymaximum);
	}

    if (juliamode>0) { cnew=julia; } else { cnew=gy2; }
	lastz=gy2;
	for(i=0; i<maxiterations; i++)
	{
		if (i==0) { firstiteration=1; } else { firstiteration=0; }
		itercount=i;
		IterateFormula(gy2,cnew);

			Z=gy2;
            radius=Z.x*Z.x+Z.y*Z.y+Z.z*Z.z;
			if (radius>bailoutsquared) { break; }
		//spikes
		Z.y=min(Z.y,ymaximum);
	}

    if (juliamode>0) { cnew=julia; } else { cnew=gz1; }
	lastz=gz1;
	for(i=0; i<maxiterations; i++)
	{
		if (i==0) { firstiteration=1; } else { firstiteration=0; }
		itercount=i;
		IterateFormula(gz1,cnew);

			Z=gz1;
            radius=Z.x*Z.x+Z.y*Z.y+Z.z*Z.z;
			if (radius>bailoutsquared) { break; }
		//spikes
		Z.y=min(Z.y,ymaximum);
	}

    if (juliamode>0) { cnew=julia; } else { cnew=gz2; }
	lastz=gz2;
	for(i=0; i<maxiterations; i++)
	{
		if (i==0) { firstiteration=1; } else { firstiteration=0; }
		itercount=i;
		IterateFormula(gz2,cnew);

			Z=gz2;
            radius=Z.x*Z.x+Z.y*Z.y+Z.z*Z.z;
			if (radius>bailoutsquared) { break; }
		//spikes
		Z.y=min(Z.y,ymaximum);
	}
    
	grad.x=(gx2.x*gx2.x+gx2.y*gx2.y+gx2.z*gx2.z)-(gx1.x*gx1.x+gx1.y*gx1.y+gx1.z*gx1.z);
    grad.y=(gy2.x*gy2.x+gy2.y*gy2.y+gy2.z*gy2.z)-(gy1.x*gy1.x+gy1.y*gy1.y+gy1.z*gy1.z);
    grad.z=(gz2.x*gz2.x+gz2.y*gz2.y+gz2.z*gz2.z)-(gz1.x*gz1.x+gz1.y*gz1.y+gz1.z*gz1.z);
	N=normalize(grad);
	return N;
	
}

vec3 Phong(in vec3 eye, in vec3 pt, in vec3 N) {
	vec3 diffuse,tmp,VectorToLight,E,NdotL,Reflected,DirectionToViewer,ReflectanceRay;
	float DiffuseFactor,r,g,b,shade,surfacer,surfaceg,surfaceb,totalr,totalg,totalb,specularfactor,mag,dist;
	int i;
	
	if (shadingstyle==0) {
		//tint with color palette based on angle to first light
		//ambient color - base color of shading
		diffuse.x=ambient;
		diffuse.y=ambient;
		diffuse.z=ambient;
		//return diffuse;
		//lambert shading
		// find the vector to the light
		//float3 L     = normalize( light - pt );
		VectorToLight=normalize(lightpositions[0]-pt);
		// find the vector to the eye
		//float3 E     = normalize( eye   - pt );
		E=normalize(eye-pt);
		// find the cosine of the angle between light and normal
		//float  NdotL = dot( N, L );
		//NdotL.x=N.x*VectorToLight.x;
		//NdotL.y=N.y*VectorToLight.y;
		//NdotL.z=N.z*VectorToLight.z;
		NdotL=N*VectorToLight;
		//NdotL=vec3(dot(vec3(N),vec3(VectorToLight)));
		DiffuseFactor=NdotL.x+NdotL.y+NdotL.z;
		// find the reflected vector
		//float3 R     = L - 2 * NdotL * N;
		//Reflected.x=lightpositions[0].x-2*DiffuseFactor*N.x;
		//Reflected.y=lightpositions[0].y-2*DiffuseFactor*N.y;
		//Reflected.z=lightpositions[0].z-2*DiffuseFactor*N.z;
		Reflected=lightpositions[0]-2.0*DiffuseFactor*N;
		//if (DiffuseFactor<0) { DiffuseFactor=0; }
		// compute the illumination using the Phong equation
		diffuse=diffuse*max(DiffuseFactor,0.0);
		//diffuse=diffuse*DiffuseFactor;
		r=diffuse.x;
		g=diffuse.y;
		b=diffuse.z;

		//shade based on phong color
		if (r>1.0) {r=1.0;}
		if (g>1.0) {g=1.0;}
		if (b>1.0) {b=1.0;}
		shade=(r+b+g)/3.0;
	
		surfacer=palette[int(shade*255.0)].r;
		surfaceg=palette[int(shade*255.0)].g;
		surfaceb=palette[int(shade*255.0)].b;
    }
	if (shadingstyle==1) {
        //tint with color palette based on radial shading
        //mag=sqrt(sqr(pt.x)+sqr(pt.y)+sqr(pt.z));
		mag=length(pt);
        //scale radius by 2 or 3 depending on if a negative power is selected
        //positive powers have max radius 2, neg powers have max radius 3
        //if pow>0 then dist:=mag/2 else dist:=mag/3;
        if (power>0.0) { dist=mag/1.5; } else { dist=mag/2.0; }
        //mandelbox scaling needs to be much larger
        if (formula==6) { dist=mag/12.0; }
		//kaleidoscopic ifs
		if (formula==7) { dist=mag/1.8; }

		surfacer=palette[int(dist*255.0)].r;
		surfaceg=palette[int(dist*255.0)].g;
		surfaceb=palette[int(dist*255.0)].b;
	}
	if (shadingstyle==2) {
        //shading based on orbit distance
        if (smallestorbit<minorbit) { smallestorbit=minorbit; }
        if (smallestorbit>maxorbit) { smallestorbit=maxorbit; }
        smallestorbit=(smallestorbit-minorbit)/(maxorbit-minorbit);
		surfacer=palette[int(smallestorbit*255.0)].r;
		surfaceg=palette[int(smallestorbit*255.0)].g;
		surfaceb=palette[int(smallestorbit*255.0)].b;
	}
	if (shadingstyle==3) {
		//ambient only
		surfacer=ambient;
		surfaceg=ambient;
		surfaceb=ambient;
	}
    
	totalr=surfacer*ambient;
    totalg=surfaceg*ambient;
    totalb=surfaceb*ambient;
	
	//contribution from lights
	for (i=0;i<7;i++) {
		if (lightsenabled[i]==1) {

        //lambert shading
        // find the vector to the light
        //float3 L     = normalize( light - pt );
        
		tmp.x=lightpositions[i].x-pt.x;
        tmp.y=lightpositions[i].y-pt.y;
        tmp.z=lightpositions[i].z-pt.z;
        mag=1.0/sqrt(tmp.x*tmp.x+tmp.y*tmp.y+tmp.z*tmp.z);
        VectorToLight.x=tmp.x*mag;
        VectorToLight.y=tmp.y*mag;
        VectorToLight.z=tmp.z*mag;
		
		VectorToLight=normalize(lightpositions[i]-pt);
		
        // find the cosine of the angle between light and normal
        //float  NdotL = dot( N, L );
        
		
		NdotL.x=N.x*VectorToLight.x;
        NdotL.y=N.y*VectorToLight.y;
        NdotL.z=N.z*VectorToLight.z;
		
		//NdotL=normalize(dot(N,VectorToLight));
		
        DiffuseFactor=NdotL.x+NdotL.y+NdotL.z;
		if (DiffuseFactor<0.0) { DiffuseFactor=0.0; }

        //specularity
        // find the vector to the eye
        //float3 E     = normalize( eye   - pt );
        /*
		tmp.x=eye.x-pt.x;
        tmp.y=eye.y-pt.y;
        tmp.z=eye.z-pt.z;
        mag=1.0/sqrt(tmp.x*tmp.x+tmp.y*tmp.y+tmp.z*tmp.z);
        DirectionToViewer.x=tmp.x*mag;
        DirectionToViewer.y=tmp.y*mag;
        DirectionToViewer.z=tmp.z*mag;
		*/
		DirectionToViewer=normalize(eye-pt);
		
        //ReflectanceRay =  2 * Dot(N, VectorToLight) * N - VectorToLight;
        /*
		tmp.x=N.x*VectorToLight.x;
        tmp.y=N.y*VectorToLight.y;
        tmp.z=N.z*VectorToLight.z;
        ReflectanceRay.x=2.0*(tmp.x+tmp.y+tmp.z)*N.x-VectorToLight.x;
        ReflectanceRay.y=2.0*(tmp.x+tmp.y+tmp.z)*N.y-VectorToLight.y;
        ReflectanceRay.z=2.0*(tmp.x+tmp.y+tmp.z)*N.z-VectorToLight.z;
		*/
		ReflectanceRay=2*dot(N,VectorToLight)*N-VectorToLight;
		
        //Calc specular factor. In mathematical terms: SpecFac = (R dot N)^Spec
		if (specon==1) {
             
			 tmp.x=ReflectanceRay.x*DirectionToViewer.x;
             tmp.y=ReflectanceRay.y*DirectionToViewer.y;
             tmp.z=ReflectanceRay.z*DirectionToViewer.z;
             //specularfactor=pow(tmp.x+tmp.y+tmp.z,specamount);
             specularfactor=pow(abs(tmp.x+tmp.y+tmp.z),specamount);
			 
		 } else {
			specularfactor=0.0;
		}

        totalr+=surfacer*DiffuseFactor*lightcolors[i].r*lightintensities[i] + specularfactor;
        totalg+=surfaceg*DiffuseFactor*lightcolors[i].g*lightintensities[i] + specularfactor;
        totalb+=surfaceb*DiffuseFactor*lightcolors[i].b*lightintensities[i] + specularfactor;		
		
		
		}
	}
	
	/*
	clamp(totalr,0.0,1.0);
	clamp(totalg,0.0,1.0);
	clamp(totalb,0.0,1.0);
	*/
	
	
	if (totalr>1.0) {totalr=1.0;}
	if (totalg>1.0) {totalg=1.0;}
	if (totalb>1.0) {totalb=1.0;}

	if (totalr<0.0) {totalr=0.0;}
	if (totalg<0.0) {totalg=0.0;}
	if (totalb<0.0) {totalb=0.0;}
	
	
	return vec3(totalr,totalg,totalb);
}

void main( void ) {
	float rtot,gtot,btot,atot,thisr,thisg,thisb,thisa,aspect,beta,alpha,amin,amax,bmin,bmax,awidth,bheight,xstep,ystep,xp,yp;
	int shadowhits,loop;
	vec3 N,T,B,L,rO,rD,Ntmp;
	
	
	//count number of lights
	numlights=0;
	for (i=0;i<7;i++) {
		if (lightsenabled[i]>0) {
			numlights+=1;
		}
	}
	
	//construct the basis
	N=normalize(lookat-eye);
	T=normalize(up);
	B=cross(N,T);
    aspect=resolution.x/resolution.y;
    beta=tan(fov*pidiv180)/2.0;
    alpha=beta*aspect;
    amin=-alpha;
    amax=alpha;
    bmin=-beta;
    bmax=beta;
    awidth=amax-amin;
    bheight=bmax-bmin;
    xstep=awidth/resolution.x;
    ystep=bheight/resolution.y;
	
	//del=epsilon/float(samplepixels)*2.0;
	del=epsilon/10.0;
	
	bailoutsquared=bailout*bailout;
	
	finalcol=vec4(0,0,0,1.0);
	
	rtot=0.0;
	gtot=0.0;
	btot=0.0;
	atot=0.0;
	
	for (supery=0;supery<samplepixels;supery++)
	{
		for (superx=0;superx<samplepixels;superx++)
		{
			thisr=0.0;
			thisg=0.0;
			thisb=0.0;
			thisa=1.0;
			
            //x and y locations
            //these are the coordinates the ray will go through in 3d space
            xp=(gl_FragCoord.x/resolution.x)*awidth-abs(amin)+(xstep*float(superx)/float(samplepixels))-xstep*0.5;
            yp=bheight-(gl_FragCoord.y/resolution.y)*bheight-abs(bmin)+(ystep*float(supery)/float(samplepixels))-ystep*0.5;

            //set ray direction vector
			rD=normalize(xp*T+yp*B+N);

            //ray origin - starts from the eye location
			rO=eye;

            //rotations
            Rotate(xrot,yrot,zrot,rO.x,rO.y,rO.z,0.0,0.0,0.0,rO.x,rO.y,rO.z);
            Rotate(xrot,yrot,zrot,rD.x,rD.y,rD.z,0.0,0.0,0.0,rD.x,rD.y,rD.z);

            //for depth of field - need eye position after it has been rotated
            roteye=rO;

            dist=FindDistance(rO,rD);

            //save desteps from this stage for glow calcs later
            float saveddesteps=desteps;
			
			if (dist<epsilon) {
				
				Ntmp=EstimateNormal(rO);
				
				thiscolor=vec4(Phong(rD,rO,Ntmp),thisa);
				thisr=thiscolor.r;
				thisg=thiscolor.g;
				thisb=thiscolor.b;
				
				//alpha
				atot=atot+1.0;
				
								
                //ambient occlusion based on min dist
                if (ambientocclusion==1) {
                     if (smallestorbit<minorbit) { smallestorbit=minorbit; }
                     if (smallestorbit>maxorbit) { smallestorbit=maxorbit; }
                     smallestorbit=(smallestorbit-minorbit)/(maxorbit-minorbit);
                     thisr=thisr*smallestorbit;
                     thisg=thisg*smallestorbit;
                     thisb=thisb*smallestorbit;
                }
						

                //interior glow effect
                if (gloweffect==1) {
					float glowr=glowcolor.r;
					float glowg=glowcolor.g;
					float glowb=glowcolor.b;
					float glowamount=saveddesteps/glowthreshold;
					thisr=thisr+glowr*glowamount;
					thisg=thisg+glowg*glowamount;
					thisb=thisb+glowb*glowamount;
					clamp(thisr,0.0,1.0);
					clamp(thisg,0.0,1.0);
					clamp(thisb,0.0,1.0);
				}
					

						
				//if the shadow flag is on, determine if this point is in shadow
				if (shadows==1) {
					shadowhits=0;
					for (loop=0;loop<7;loop++) {
						if (lightsenabled[loop]==1) {
							L=normalize(lightpositions[loop]-rO);
                            /*
							L.x=lightpositions[loop].x-rO.x;
                            L.y=lightpositions[loop].y-rO.y;
                            L.z=lightpositions[loop].z-rO.z;

                            mag=1/sqrt(L.x*L.x+L.y*L.y+L.z*L.z);
                            L.x=L.x*mag;
                            L.y=L.y*mag;
                            L.z=L.z*mag;
							*/
							//rO += N*epsilon*2.0;
							rO=rO+Ntmp*epsilon*2.0;
							dist=FindDistance(rO,L);
							if(dist<epsilon) { shadowhits+=1; }
						}
					}
					//darken pixel only if the area is shadowed by ALL the lights
					//if shadowhits=numlights then thiscolor:=rgb(trunc(getrvalue(thiscolor)*shadowintensity),trunc(getgvalue(thiscolor)*shadowintensity),trunc(getbvalue(thiscolor)*shadowintensity));
					//darken by amount of lights in shadow
					//shadowfactor=1.0-shadowintensity/shadowhits;
					shadowfactor=shadowintensity*float(shadowhits/numlights);
					if (shadowhits==numlights) {
					//if (shadowhits>0) {
						thisr=thisr*shadowfactor;
						thisg=thisg*shadowfactor;
						thisb=thisb*shadowfactor;
					}	
				}
				
				
			}
			else
			{
				
				//thisr=thisr+backgroundcolor.r;
				//thisg=thisg+backgroundcolor.g;
				//thisb=thisb+backgroundcolor.b;
				
				//backbuffer holds background color or background image pixels
				//backbuffer prefilled and passed by voc
				vec2 position = ( gl_FragCoord.xy / resolution.xy );
				thisr=thisr+texture2D(backbuffer,position).r;
				thisg=thisg+texture2D(backbuffer,position).g;
				thisb=thisb+texture2D(backbuffer,position).b;

				
                //exterior glow effect
                if (gloweffect==1 && outsideglow==1) {
					float glowr=glowcolor.r;
					float glowg=glowcolor.g;
					float glowb=glowcolor.b;
					float glowamount=saveddesteps/glowthreshold;
					thisr=thisr+glowr*glowamount;
					thisg=thisg+glowg*glowamount;
					thisb=thisb+glowb*glowamount;
					clamp(thisr,0.0,1.0);
					clamp(thisg,0.0,1.0);
					clamp(thisb,0.0,1.0);
				}
			}
			
			
			//gamma/brightness setting
            if (gamma!=0.0) {
				thisr=thisr+thisr*gamma/100.0;
                thisg=thisg+thisg*gamma/100.0;
                thisb=thisb+thisb*gamma/100.0;
				clamp(thisr,0.0,1.0);
				clamp(thisg,0.0,1.0);
				clamp(thisb,0.0,1.0);
			}

            
            //contrast
            if (contrast!=0.0) {
				thisr=thisr+((thisr-0.5)*contrast/100.0);
                thisg=thisg+((thisg-0.5)*contrast/100.0);
                thisb=thisb+((thisb-0.5)*contrast/100.0);
				clamp(thisr,0.0,1.0);
				clamp(thisg,0.0,1.0);
				clamp(thisb,0.0,1.0);
			}
			
            rtot=rtot+thisr;
            gtot=gtot+thisg;
            btot=btot+thisb;
			//alpha does not increase for background
			atot=atot+0;
		}
	}

	rtot=rtot/float(samplepixels*samplepixels);
	gtot=gtot/float(samplepixels*samplepixels);
	btot=btot/float(samplepixels*samplepixels);
	atot=atot/float(samplepixels*samplepixels);

	glFragColor=vec4(rtot,gtot,btot,atot);
}

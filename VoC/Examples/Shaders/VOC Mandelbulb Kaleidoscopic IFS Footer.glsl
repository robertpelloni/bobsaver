
//specific iteration code before this line

void IterateFormula(inout vec3 z, in vec3 c) {
	float scale,fixedradius,minradius,fr2,mr2,r2,fr2divmr2,fr2divr2;
	
	Iterate(z,c);
    
         radius=z.x*z.x+z.y*z.y+z.z*z.z;
         //ambient occlusion
         if (radius<smallestorbit) { smallestorbit=radius; }
         //stop when we know the point diverges.
         if (radius>bailout) { return; }
	
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
    
	while (maxsteps<1024) { //VERY important to avoid endless loops that hang GPU
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
		
		
        //Kaleidoscopic IFS pre rotation 1
			if (kprerotate==1) {
				if (krotatearoundorigin==1) {
					x1=rotmat1[0][0]*Z.x+rotmat1[1][0]*Z.y+rotmat1[2][0]*Z.z;
					y1=rotmat1[0][1]*Z.x+rotmat1[1][1]*Z.y+rotmat1[2][1]*Z.z;
					z1=rotmat1[0][2]*Z.x+rotmat1[1][2]*Z.y+rotmat1[2][2]*Z.z;
					Z.x=x1;Z.y=y1;Z.z=z1;
				} else {
					Rotate( kr1x,kr1y,kr1z,
							Z.x,Z.y,Z.z,
							kcx,kcy,kcz,
							Z.x,Z.y,Z.z);
				}
			}
		
		
		
		for(i=0; i<maxiterations; i++)
		{
			if (i==0) { firstiteration=1; } else { firstiteration=0; }
			itercount=i;
			IterateFormula(Z,C);
			//dr=zr*dr*power+1.0;
			dr=radius*dr*power+1.0;
			if (radius>bailout) {break;}
			
			//spikes
			if (spikes>0) { if (Z.y>ymaximum) {Z.y=ymaximum;} }
        }
        
		//for glsl the following line needed the /2.0 added for correct DE
		dist=(sqrt(radius)-2.0)*pow(power,float(-itercount))/2.0;
		dist=dist*descalefactor;
		rO=rO+rD*dist;
		
        //glow
        desteps+=1;
        if (desteps>glowthreshold) { desteps=glowthreshold; }
		
		
            bailouttest=rO.x*rO.x+rO.y*rO.y+rO.z*rO.z;
			if (dist<eps) { break; }
			if (bailouttest>bailout) { break; }
		
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
	
    //Kaleidoscopic IFS rotations
		if (kprerotate==1) {
			if (krotatearoundorigin==1) {
				x1=rotmat1[0][0]*gx1.x+rotmat1[1][0]*gx1.y+rotmat1[2][0]*gx1.z;
				y1=rotmat1[0][1]*gx1.x+rotmat1[1][1]*gx1.y+rotmat1[2][1]*gx1.z;
				z1=rotmat1[0][2]*gx1.x+rotmat1[1][2]*gx1.y+rotmat1[2][2]*gx1.z;
				gx1.x=x1;gx1.y=y1;gx1.z=z1;
			} else {
				Rotate( kr1x,kr1y,kr1z,
						gx1.x,gx1.y,gx1.z,
						kcx,kcy,kcz,
						gx1.x,gx1.y,gx1.z);
			}
		}
    if (juliamode>0) { cnew=julia; } else { cnew=gx1; }
	lastz=gx1;
	for(i=0; i<maxiterations; i++)
	{
		if (i==0) { firstiteration=1; } else { firstiteration=0; }
		IterateFormula(gx1,cnew);

			Z=gx1;
            radius=Z.x*Z.x+Z.y*Z.y+Z.z*Z.z;
            if (radius>bailout) { break; }
		//spikes
		if (spikes>0) { if (Z.y>ymaximum) {Z.y=ymaximum;} }
	}

    //Kaleidoscopic IFS rotations
		if (kprerotate==1) {
			if (krotatearoundorigin==1) {
				x1=rotmat1[0][0]*gx2.x+rotmat1[1][0]*gx2.y+rotmat1[2][0]*gx2.z;
				y1=rotmat1[0][1]*gx2.x+rotmat1[1][1]*gx2.y+rotmat1[2][1]*gx2.z;
				z1=rotmat1[0][2]*gx2.x+rotmat1[1][2]*gx2.y+rotmat1[2][2]*gx2.z;
				gx2.x=x1;gx2.y=y1;gx2.z=z1;
			} else {
				Rotate( kr1x,kr1y,kr1z,
						gx2.x,gx2.y,gx2.z,
						kcx,kcy,kcz,
						gx2.x,gx2.y,gx2.z);
			}
		}
    if (juliamode>0) { cnew=julia; } else { cnew=gx2; }
	lastz=gx2;
	for(i=0; i<maxiterations; i++)
	{
		if (i==0) { firstiteration=1; } else { firstiteration=0; }
		IterateFormula(gx2,cnew);

			Z=gx2;
            radius=Z.x*Z.x+Z.y*Z.y+Z.z*Z.z;
            if (radius>bailout) { break; }
		//spikes
		if (spikes>0) { if (Z.y>ymaximum) {Z.y=ymaximum;} }
	}

    //Kaleidoscopic IFS rotations
		if (kprerotate==1) {
			if (krotatearoundorigin==1) {
				x1=rotmat1[0][0]*gy1.x+rotmat1[1][0]*gy1.y+rotmat1[2][0]*gy1.z;
				y1=rotmat1[0][1]*gy1.x+rotmat1[1][1]*gy1.y+rotmat1[2][1]*gy1.z;
				z1=rotmat1[0][2]*gy1.x+rotmat1[1][2]*gy1.y+rotmat1[2][2]*gy1.z;
				gy1.x=x1;gy1.y=y1;gy1.z=z1;
			} else {
				Rotate( kr1x,kr1y,kr1z,
						gy1.x,gy1.y,gy1.z,
						kcx,kcy,kcz,
						gy1.x,gy1.y,gy1.z);
			}
		}
	if (juliamode>0) { cnew=julia; } else { cnew=gy1; }
	lastz=gy1;
	for(i=0; i<maxiterations; i++)
	{
		if (i==0) { firstiteration=1; } else { firstiteration=0; }
		IterateFormula(gy1,cnew);

			Z=gy1;
            radius=Z.x*Z.x+Z.y*Z.y+Z.z*Z.z;
            if (radius>bailout) { break; }
		//spikes
		if (spikes>0) { if (Z.y>ymaximum) {Z.y=ymaximum;} }
	}

    //Kaleidoscopic IFS rotations
		if (kprerotate==1) {
			if (krotatearoundorigin==1) {
				x1=rotmat1[0][0]*gy2.x+rotmat1[1][0]*gy2.y+rotmat1[2][0]*gy2.z;
				y1=rotmat1[0][1]*gy2.x+rotmat1[1][1]*gy2.y+rotmat1[2][1]*gy2.z;
				z1=rotmat1[0][2]*gy2.x+rotmat1[1][2]*gy2.y+rotmat1[2][2]*gy2.z;
				gy2.x=x1;gy2.y=y1;gy2.z=z1;
			} else {
				Rotate( kr1x,kr1y,kr1z,
						gy2.x,gy2.y,gy2.z,
						kcx,kcy,kcz,
						gy2.x,gy2.y,gy2.z);
			}
		}
    if (juliamode>0) { cnew=julia; } else { cnew=gy2; }
	lastz=gy2;
	for(i=0; i<maxiterations; i++)
	{
		if (i==0) { firstiteration=1; } else { firstiteration=0; }
		IterateFormula(gy2,cnew);

			Z=gy2;
            radius=Z.x*Z.x+Z.y*Z.y+Z.z*Z.z;
            if (radius>bailout) { break; }
		//spikes
		if (spikes>0) { if (Z.y>ymaximum) {Z.y=ymaximum;} }
	}

    //Kaleidoscopic IFS rotations
		if (kprerotate==1) {
			if (krotatearoundorigin==1) {
				x1=rotmat1[0][0]*gz1.x+rotmat1[1][0]*gz1.y+rotmat1[2][0]*gz1.z;
				y1=rotmat1[0][1]*gz1.x+rotmat1[1][1]*gz1.y+rotmat1[2][1]*gz1.z;
				z1=rotmat1[0][2]*gz1.x+rotmat1[1][2]*gz1.y+rotmat1[2][2]*gz1.z;
				gz1.x=x1;gz1.y=y1;gz1.z=z1;
			} else {
				Rotate( kr1x,kr1y,kr1z,
						gz1.x,gz1.y,gz1.z,
						kcx,kcy,kcz,
						gz1.x,gz1.y,gz1.z);
			}
		}
    if (juliamode>0) { cnew=julia; } else { cnew=gz1; }
	lastz=gz1;
	for(i=0; i<maxiterations; i++)
	{
		if (i==0) { firstiteration=1; } else { firstiteration=0; }
		IterateFormula(gz1,cnew);

			Z=gz1;
            radius=Z.x*Z.x+Z.y*Z.y+Z.z*Z.z;
            if (radius>bailout) { break; }
		//spikes
		if (spikes>0) { if (Z.y>ymaximum) {Z.y=ymaximum;} }
	}

    //Kaleidoscopic IFS rotations
		if (kprerotate==1) {
			if (krotatearoundorigin==1) {
				x1=rotmat1[0][0]*gz2.x+rotmat1[1][0]*gz2.y+rotmat1[2][0]*gz2.z;
				y1=rotmat1[0][1]*gz2.x+rotmat1[1][1]*gz2.y+rotmat1[2][1]*gz2.z;
				z1=rotmat1[0][2]*gz2.x+rotmat1[1][2]*gz2.y+rotmat1[2][2]*gz2.z;
				gz2.x=x1;gz2.y=y1;gz2.z=z1;
			} else {
				Rotate( kr1x,kr1y,kr1z,
						gz2.x,gz2.y,gz2.z,
						kcx,kcy,kcz,
						gz2.x,gz2.y,gz2.z);
			}
		}
    if (juliamode>0) { cnew=julia; } else { cnew=gz2; }
	lastz=gz2;
	for(i=0; i<maxiterations; i++)
	{
		if (i==0) { firstiteration=1; } else { firstiteration=0; }
		IterateFormula(gz2,cnew);

			Z=gz2;
            radius=Z.x*Z.x+Z.y*Z.y+Z.z*Z.z;
            if (radius>bailout) { break; }
		//spikes
		if (spikes>0) { if (Z.y>ymaximum) {Z.y=ymaximum;} }
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
	
	
	//KIFS setups
	if (formula==7) {
		salpha=kr1z;
		sbeta=kr1y;
		stheta=kr1x;
		s1=sin(sbeta);c1=cos(sbeta);
		s2=sin(stheta);c2=cos(stheta);
		s3=sin(salpha);c3=cos(salpha);
		rotmat1[0][0]=c1*c3+s1*s2*s3; rotmat1[0][1]=c2*s3; rotmat1[0][2]=c1*s2*s3-c3*s1;
		rotmat1[1][0]=c3*s1*s2-c1*s3; rotmat1[1][1]=c2*c3; rotmat1[1][2]=s1*s3+c1*c3*s2;
		rotmat1[2][0]=c2*s1;          rotmat1[2][1]=-s2;   rotmat1[2][2]=c1*c2;
		salpha=kr2z;
		sbeta=kr2y;
		stheta=kr2x;
		s1=sin(sbeta);c1=cos(sbeta);
		s2=sin(stheta);c2=cos(stheta);
		s3=sin(salpha);c3=cos(salpha);
		rotmat2[0][0]=c1*c3+s1*s2*s3; rotmat2[0][1]=c2*s3; rotmat2[0][2]=c1*s2*s3-c3*s1;
		rotmat2[1][0]=c3*s1*s2-c1*s3; rotmat2[1][1]=c2*c3; rotmat2[1][2]=s1*s3+c1*c3*s2;
		rotmat2[2][0]=c2*s1;          rotmat2[2][1]=-s2;   rotmat2[2][2]=c1*c2;
		//constrain center of rotation to the unit sphere
		//easiest way is to normalise the xyz
		if (normalizekc==1) {
			mag=1.0/sqrt(kcxuniform*kcxuniform+kcyuniform*kcyuniform+kczuniform*kczuniform);
			kcx=kcxuniform*mag;
			kcy=kcyuniform*mag;
			kcz=kczuniform*mag;
		} else {
			kcx=kcxuniform;
			kcy=kcyuniform;
			kcz=kczuniform;
		}
		kphi=(0.5*(1.0+sqrt(5.0))); // Phi is the golden ratio
		//The three points that are the vertices of a fundamental triangle.
		//vertex
		ftris[0]=kphi;
		ftris[1]=1.0;
		ftris[2]=0.0;
		//middle of edge
		ftria[0]=kphi;
		ftria[1]=0.0;
		ftria[2]=0.0;
		//center of an icosa triangle
		ftric[0]=1.0/3.0*(1.0+2.0*kphi);
		ftric[1]=0.0;
		ftric[2]=kphi/3.0;
		//This is the normalisation factor of the following vector
		in3=(1.0/sqrt(14.0+6.0*sqrt(5.0)));
		//this is the normal of one of the folding planes
		// The 2 others planes' normals are: {0,1,0} and {0,0,1}
		n3[0]=in3*kphi;
		n3[1]=-in3*(kphi*kphi);
		n3[2]=-in3*(2.0*kphi+1.0);
	}
	
	
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
				
				thiscolor=vec4(Phong(rD,rO,Ntmp),1.0);
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
					if (thisr<0.0) { thisr=0.0; }
					if (thisr>1.0) { thisr=1.0; }
					if (thisg<0.0) { thisg=0.0; }
					if (thisg>1.0) { thisg=1.0; }
					if (thisb<0.0) { thisb=0.0; }
					if (thisb>1.0) { thisb=1.0; }
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
					//shadowfactor:=1-shadowintensity/shadowhits;
					shadowfactor=shadowintensity*float(shadowhits/numlights);
					if (shadowhits==numlights) {
						thisr=thisr*shadowfactor;
						thisg=thisg*shadowfactor;
						thisb=thisb*shadowfactor;
					}	
				}
				
				
			}
			else
			{
				//thiscolor=vec4(0.0,0.0,0.0,1.0);
				thisr=thisr+backgroundcolor.r;
				thisg=thisg+backgroundcolor.g;
				thisb=thisb+backgroundcolor.b;

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
					if (thisr<0.0) { thisr=0.0; }
					if (thisr>1.0) { thisr=1.0; }
					if (thisg<0.0) { thisg=0.0; }
					if (thisg>1.0) { thisg=1.0; }
					if (thisb<0.0) { thisb=0.0; }
					if (thisb>1.0) { thisb=1.0; }
				}

			}
			
			
			//gamma/brightness setting
            if (gamma!=0.0) {
				thisr=thisr+thisr*gamma/100.0;
                thisg=thisg+thisg*gamma/100.0;
                thisb=thisb+thisb*gamma/100.0;
				if (thisr<0.0) { thisr=0.0; }
				if (thisr>1.0) { thisr=1.0; }
				if (thisg<0.0) { thisg=0.0; }
				if (thisg>1.0) { thisg=1.0; }
				if (thisb<0.0) { thisb=0.0; }
				if (thisb>1.0) { thisb=1.0; }
			}

            
            //contrast
            if (contrast!=0.0) {
				thisr=thisr+((thisr-0.5)*contrast/100.0);
                thisg=thisg+((thisg-0.5)*contrast/100.0);
                thisb=thisb+((thisb-0.5)*contrast/100.0);
				if (thisr<0.0) { thisr=0.0; }
				if (thisr>1.0) { thisr=1.0; }
				if (thisg<0.0) { thisg=0.0; }
				if (thisg>1.0) { thisg=1.0; }
				if (thisb<0.0) { thisb=0.0; }
				if (thisb>1.0) { thisb=1.0; }
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

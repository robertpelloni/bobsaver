void Iterate(inout vec3 z,in vec3 c) {
	float scale,fixedradius,minradius,fr2,mr2,r2,fr2divmr2,fr2divr2,x1,y1,z1,t;
    scale=power;

    //rotation 1
    if (kprerotate==0) {
		if (krotatearoundorigin==1) {
			x1=rotmat1[0][0]*z.x+rotmat1[1][0]*z.y+rotmat1[2][0]*z.z;
			y1=rotmat1[0][1]*z.x+rotmat1[1][1]*z.y+rotmat1[2][1]*z.z;
			z1=rotmat1[0][2]*z.x+rotmat1[1][2]*z.y+rotmat1[2][2]*z.z;
			z.x=x1;z.y=y1;z.z=z1;
		} else {
			Rotate( kr1x,kr1y,kr1z,
					z.x,z.y,z.z,
					kcx,kcy,kcz,
					z.x,z.y,z.z );
		}
	}

	//Folding... These are some of the symmetry planes of the tetrahedron
	if (kfold==0) {
                //half tetrahedral
                if (z.x+z.y<0) {
                     x1=-z.y;
                     z.y=-z.x;
                     z.x=x1;
                }
                if(z.x+z.z<0) {
                     x1=-z.z;
                     z.z=-z.x;
                     z.x=x1;
				}
                if(z.y+z.z<0) {
                     y1=-z.z;
                     z.z=-z.y;
                     z.y=y1;
				}
	}
	if (kfold==1) {
                //2nd half tetrahedral
                if(z.x-z.y<0) {
                     x1=z.y;
                     z.y=z.x;
                     z.x=x1;
				}
                if(z.x-z.z<0) {
                     x1=z.z;
                     z.z=z.x;
                     z.x=x1;
				}
                if(z.y-z.z<0) {
                     y1=z.z;
                     z.z=z.y;
                     z.y=y1;
				}
	}
	if (kfold==2) {
                //full tetrahedral
                if(z.x-z.y<0) {
                     x1=z.y;
                     z.y=z.x;
                     z.x=x1;
				}
                if(z.x-z.z<0) {
                     x1=z.z;
                     z.z=z.x;
                     z.x=x1;
				}
                if(z.y-z.z<0) {
                     y1=z.z;
                     z.z=z.y;
                     z.y=y1;
				}
                if(z.x+z.y<0) {
                     x1=-z.y;
                     z.y=-z.x;
                     z.x=x1;
				}
                if(z.x+z.z<0) {
                     x1=-z.z;
                     z.z=-z.x;
                     z.x=x1;
				}
                if(z.y+z.z<0) {
                     y1=-z.z;
                     z.z=-z.y;
                     z.y=y1;
				}
	}
	if (kfold==3) {
                //cubic
                z.x=abs(z.x);
                z.y=abs(z.y);
                z.z=abs(z.z);
	}
	if (kfold==4) {
                //half octahedral
                if (z.x-z.y<0) {
                     x1=z.y;
                     z.y=z.x;
                     z.x=x1;
				}
                if (z.x+z.y<0) {
                     x1=-z.y;
                     z.y=-z.x;
                     z.x=x1;
				}
                if (z.x-z.z<0) {
                     x1=z.z;
                     z.z=z.x;
                     z.x=x1;
				}
                if (z.x+z.z<0) {
                     x1=-z.z;
                     z.z=-z.x;
                     z.x=x1;
				}
	}
	if (kfold==5) {
                //full octahedral
                z.x=abs(z.x);
                z.y=abs(z.y);
                z.z=abs(z.z);
                if (z.x-z.y<0) {
                     x1=z.y;
                     z.y=z.x;
                     z.x=x1;
				}
                if (z.x-z.z<0) {
                     x1=z.z;
                     z.z=z.x;
                     z.x=x1;
				}
                if (z.y-z.z<0) {
                     y1=z.z;
                     z.z=z.y;
                     z.y=y1;
				}
	}
	if (kfold==6) {
                //octo sierpinski
                if (z.x+z.y<0) {
                     x1=-z.y;
                     z.y=-z.x;
                     z.x=x1;
				}			
                if (z.x+z.z<0) {
                     x1=-z.z;
                     z.z=-z.x;
                     z.x=x1;
				}			
                if (z.x-z.y<0) {
                     x1=z.y;
                     z.y=z.x;
                     z.x=x1;
				}			
                if (z.x-z.z<0) {
                     x1=z.z;
                     z.z=z.x;
                     z.x=x1;
				}			
	}
	if (kfold==7) {
                //icosahedron
                z.x=abs(z.x);
                z.y=abs(z.y);
                z.z=abs(z.z);
                t=z.x*n3[0]+z.y*n3[1]+z.z*n3[2];
                if(t<0) {
                     z.x=z.x-2*t*n3[0];
                     z.y=z.y-2*t*n3[1];
                     z.z=z.z-2*t*n3[2];
				}			
                z.y=abs(z.y);
                z.z=abs(z.z);
                t=z.x*n3[0]+z.y*n3[1]+z.z*n3[2];
                if(t<0) {
                     z.x=z.x-2*t*n3[0];
                     z.y=z.y-2*t*n3[1];
                     z.z=z.z-2*t*n3[2];
				}			
                z.y=abs(z.y);
                z.z=abs(z.z);
                t=z.x*n3[0]+z.y*n3[1]+z.z*n3[2];
                if(t<0) {
                     z.x=z.x-2*t*n3[0];
                     z.y=z.y-2*t*n3[1];
                     z.z=z.z-2*t*n3[2];
				}			
	}
	if (kfold==8) {
                //dodecahedron
                z.x=abs(z.x);
                z.y=abs(z.y);
                z.z=abs(z.z);
                t=z.x*n3[0]+z.y*n3[1]+z.z*n3[2];
                if(t<0) {
                     z.x=z.x-2*t*n3[0];
                     z.y=z.y-2*t*n3[1];
                     z.z=z.z-2*t*n3[2];
				}
                z.y=abs(z.y);
                z.z=abs(z.z);
                t=z.x*n3[0]+z.y*n3[1]+z.z*n3[2];
                if(t<0) {
                     z.x=z.x-2*t*n3[0];
                     z.y=z.y-2*t*n3[1];
                     z.z=z.z-2*t*n3[2];
				}
                z.y=abs(z.y);
                z.z=abs(z.z);
                t=z.x*n3[0]+z.y*n3[1]+z.z*n3[2];
                if(t<0) {
                     z.x=z.x-2*t*n3[0];
                     z.y=z.y-2*t*n3[1];
                     z.z=z.z-2*t*n3[2];
				}
	}

    //rotation 2
    if (krotatearoundorigin==1) {
        x1=rotmat2[0][0]*z.x+rotmat2[1][0]*z.y+rotmat2[2][0]*z.z;
        y1=rotmat2[0][1]*z.x+rotmat2[1][1]*z.y+rotmat2[2][1]*z.z;
        z1=rotmat2[0][2]*z.x+rotmat2[1][2]*z.y+rotmat2[2][2]*z.z;
        z.x=x1;z.y=y1;z.z=z1;
	} else {
         Rotate( kr2x,kr2y,kr2z,
                 z.x,z.y,z.z,
                 kcx,kcy,kcz,
                 z.x,z.y,z.z);
	}


    //stretching
	if (kfold<7) {
		//other types stretching
		z.x=scale*z.x-kcx*(scale-1);
		z.y=scale*z.y-kcy*(scale-1);
		if (kzwrap==1) {
			z.z=scale*z.z;
			if (z.z>0.5*kcz*(scale-1)) { z.z=z.z-kcz*(scale-1); }
		} else { 
			z.z=scale*z.z-kcz*(scale-1); 
		}
	}
    if (kfold==7) {
        //icosahedral strecthing
        z.x=scale*z.x-ftris[0]*(scale-1);
        z.y=scale*z.y-ftris[1]*(scale-1);
        z.z=scale*z.z-ftris[2]*(scale-1);
	}
	if (kfold==8) {
		//dodecahedral strecthing
		z.x=scale*z.x-ftric[0]*(scale-1);
		z.y=scale*z.y-ftric[1]*(scale-1);
		z.z=scale*z.z-ftric[2]*(scale-1);
	}
	
	

}
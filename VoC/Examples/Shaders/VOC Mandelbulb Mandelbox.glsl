void Iterate(inout vec3 z,in vec3 c) {
	float scale,fixedradius,minradius,fr2,mr2,r2,fr2divmr2,fr2divr2;
    scale=power;
    if (boxfolding==0) {
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
    if (spherefolding==0) {
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
    z.x=z.x*scale+c.x;
    z.y=z.y*scale+c.y;
    z.z=z.z*scale+c.z;
    DEfactor=DEfactor*abs(scale)+1;
}
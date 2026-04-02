vec3 TriplexMultiplicationPhoenixRudyRucker(in vec3 z,in vec3 p) {
     vec3 znew;
     float r1,r2,r1r2,theta1,theta2,phi1,phi2,cosph;
     r1=length(z);
     r2=length(p);
     r1r2=r1*r2;
     theta1=atan(z.y,z.x);
     theta2=atan(p.y,p.x);
     phi1=asin(z.z/r1);
     phi2=asin(p.z/r2);
     cosph=r1r2*cos(phi1+phi2);
     znew.x=cosph*cos(theta1+theta2);
     znew.y=cosph*sin(theta1+theta2);
     znew.z=r1r2*sin(phi1+phi2);
     return znew;
}

void Iterate(inout vec3 z,in vec3 c) {
	vec3 znew,znew2;
	if (firstiteration==1) {
		theta=atan(z.y,z.x)*thetascale;
		phi=(atan(z.z/z.x)+phase)*phiscale;
	} else {
		theta=atan(z.y,z.x);
		phi=atan(z.z/z.x)+phase;
	}
	radius=pow(radius,power);
	theta=theta*power;
	phi=phi*power;
	cosphi=cos(phi);
	znew.x=radius*cos(theta)*cosphi;
	znew.y=radius*sin(theta)*cosphi;
	znew.z=radius*sin(phi);
	znew2=TriplexMultiplicationPhoenixRudyRucker(c,lastz);
	znew=znew+znew2;
	lastz=z;
	z=znew;
}

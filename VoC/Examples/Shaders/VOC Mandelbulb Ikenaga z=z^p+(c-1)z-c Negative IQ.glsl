vec3 TriplexMultiplicationIkenagaNegativeIQ(in vec3 z,in vec3 p) {
     vec3 znew;
     float r1,r2,r1r2,theta1,theta2,phi1,phi2,sinth;
     r1=length(z);
     r2=length(p);
     r1r2=r1*r2;
     theta1=atan(z.y,z.x);
     theta2=atan(p.y,p.x);
     phi1=asin(z.z/r1);
     phi2=asin(p.z/r2);
     sinth=r1r2*sin(theta1+theta2);
     znew.x=sinth*sin(phi1+phi2);
     znew.y=r1r2*cos(theta1+theta2);
     znew.z=-sinth*cos(phi1+phi2);
     return znew;
}

void Iterate(inout vec3 z,in vec3 c) {
	vec3 znew,znew2;
	if (firstiteration==1) {
		theta=acos(z.y/radius)*thetascale;
		phi=(atan(z.x/z.z)+phase)*phiscale;
	} else {
		theta=acos(z.y/radius);
		phi=atan(z.x/z.z)+phase;
	}
	radius=pow(radius,power);
	theta=theta*power;
	phi=phi*power;
	sinphi=sin(phi);
	sintheta=sin(theta);
	znew.x=radius*sintheta*sinphi;
	znew.y=radius*cos(theta);
	znew.z=-radius*sintheta*cos(phi);
	znew2=c-vec3(1.0,1.0,1.0);
	znew2=TriplexMultiplicationIkenagaNegativeIQ(znew2,z);
	znew2=znew2-c;
	znew=znew+znew2;
	lastz=z;
	z=znew;
}

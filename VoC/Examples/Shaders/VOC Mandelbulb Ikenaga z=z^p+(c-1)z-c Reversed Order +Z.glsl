vec3 TriplexMultiplicationIkenagaReversedOrder+Z(in vec3 z,in vec3 p) {
     vec3 znew;
     float r1,r2,r1r2,theta1,theta2,phi1,phi2,costh;
     r1=length(z);
     r2=length(p);
     r1r2=r1*r2;
     theta1=atan(z.y,z.x);
     theta2=atan(p.y,p.x);
     phi1=asin(z.z/r1);
     phi2=asin(p.z/r2);
     costh=r1r2*cos(theta1+theta2);
     znew.x=costh*cos(phi1+phi2);
     znew.y=r1r2*sin(theta1+theta2);
     znew.z=costh;
     return znew;
}

void Iterate(inout vec3 z,in vec3 c) {
	vec3 znew,znew2;
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
	costheta=cos(theta);
	znew.x=radius*costheta*cos(phi);
	znew.y=radius*sin(theta);
	znew.z=radius*costheta*sin(phi);
	znew2=c-vec3(1.0,1.0,1.0);
	znew2=TriplexMultiplicationIkenagaReversedOrder+Z(znew2,z);
	znew2=znew2-c;
	znew=znew+znew2;
	lastz=z;
	z=znew;
}

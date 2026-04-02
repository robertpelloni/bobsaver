void Iterate(inout vec3 z,in vec3 c) {
	vec3 znew;
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
	znew.z=radius*sintheta*cos(phi);
	znew=znew+c;
	znew=znew+lastz;
	lastz=z;
	z=znew;
}

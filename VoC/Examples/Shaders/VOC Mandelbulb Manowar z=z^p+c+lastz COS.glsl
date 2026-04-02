void Iterate(inout vec3 z,in vec3 c) {
	vec3 znew;
	if (firstiteration==1) {
		theta=atan(z.y,z.x)*thetascale;
		phi=(acos(z.z/radius)+phase)*phiscale;
	} else {
		theta=atan(z.y,z.x);
		phi=acos(z.z/radius)+phase;
	}
	radius=pow(radius,power);
	theta=theta*power;
	phi=phi*power;
	sinphi=sin(phi);
	znew.x=radius*cos(theta)*sinphi;
	znew.y=radius*sin(theta)*sinphi;
	znew.z=radius*cos(phi);
	znew=znew+c;
	znew=znew+lastz;
	lastz=z;
	z=znew;
}

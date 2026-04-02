void Iterate(inout vec3 z,in vec3 c) {
	vec3 znew;
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
	znew.x=rcosphi*cos(theta);
	znew.y=rcosphi*sin(theta);
	znew.z=radius*sin(phi);
	znew=znew+c;
	znew=znew+lastz;
	lastz=z;
	z=znew;
}

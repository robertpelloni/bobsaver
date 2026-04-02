void Iterate(inout vec3 z,in vec3 c) {
	vec3 znew;
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
	znew=znew+c;
	znew=znew+lastz;
	lastz=z;
	z=znew;
}

void Iterate(inout vec3 z,in vec3 c) {
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
	z.x=radius*cos(theta)*sinphi+c.x;
	z.y=radius*sin(theta)*sinphi+c.y;
	z.z=radius*cos(phi)+c.z;
}

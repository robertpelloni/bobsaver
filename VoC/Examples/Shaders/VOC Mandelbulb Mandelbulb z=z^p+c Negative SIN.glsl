void Iterate(inout vec3 z,in vec3 c) {
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
	z.x=rcosphi*cos(theta)+c.x;
	z.y=rcosphi*sin(theta)+c.y;
	z.z=radius*-sin(phi)+c.z;
}

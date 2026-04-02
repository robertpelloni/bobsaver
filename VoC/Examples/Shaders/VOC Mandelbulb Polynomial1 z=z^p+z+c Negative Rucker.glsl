void Iterate(inout vec3 z,in vec3 c) {
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
	z.x=radius*cos(theta)*cosphi+z.x+c.x;
	z.y=radius*sin(theta)*cosphi+z.y+c.y;
	z.z=radius*-sin(phi)+z.z+c.z;
}

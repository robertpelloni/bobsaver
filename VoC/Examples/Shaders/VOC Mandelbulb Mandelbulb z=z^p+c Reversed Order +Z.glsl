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
	costheta=cos(theta);
	z.x=radius*costheta*cos(phi)+c.x;
	z.y=radius*sin(theta)+c.y;
	z.z=radius*costheta*sin(phi)+c.z;
}

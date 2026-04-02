void Iterate(inout vec3 z,in vec3 c) {
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
	z.x=radius*sintheta*sinphi+c.x;
	z.y=radius*cos(theta)+c.y;
	z.z=radius*-sintheta*cos(phi)+c.z;
}

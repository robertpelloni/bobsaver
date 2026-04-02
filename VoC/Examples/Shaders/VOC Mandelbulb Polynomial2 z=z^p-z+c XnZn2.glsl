vec3 TriplexAdditionPolynomial2XnZn2(in vec3 z, in vec3 c) {
    vec3 znew;
    znew.x=z.x+c.x;
    znew.y=z.y+c.y;
    znew.z=z.z+c.z;
    return znew;
}

vec3 XnZn2TriplexPowerPolynomial2XnZn2(in vec3 z,in float p) {
	vec3 znew;
    radius=pow(radius,p);
    theta=theta*p;
    phi=phi*p;
	znew.x=radius*sin(phi);
    znew.y=radius*cos(phi)*cos(theta);
    znew.z=radius*-sin(theta)*cos(phi);
	return znew;
}

void Iterate(inout vec3 z,in vec3 c) {
	vec3 znew;
	theta=atan(z.y,z.x);
	phi=asin(z.z/radius)+phase;
	if (firstiteration==1) {
		theta=theta*thetascale;
		phi=phi*phiscale;
	}
    znew=XnZn2TriplexPowerPolynomial2XnZn2(z,power);
    znew=TriplexAdditionPolynomial2XnZn2(znew,-z);
    znew=TriplexAdditionPolynomial2XnZn2(znew,c);
    z=znew;
}

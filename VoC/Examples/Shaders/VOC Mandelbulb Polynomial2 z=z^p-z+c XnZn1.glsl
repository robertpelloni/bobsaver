vec3 TriplexAdditionPolynomial2XnZn1(in vec3 z, in vec3 c) {
    vec3 znew;
    znew.x=z.x+c.x;
    znew.y=z.y+c.y;
    znew.z=z.z+c.z;
    return znew;
}

vec3 XnZn1TriplexPowerPolynomial2XnZn1(in vec3 z,in float p) {
	vec3 znew;
    radius=pow(radius,p);
    theta=theta*p;
    phi=phi*p;
	znew.x=radius*cos(phi);
    znew.y=radius*sin(phi)*-cos(theta);
    znew.z=radius*sin(theta)*sin(phi);
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
    znew=XnZn1TriplexPowerPolynomial2XnZn1(z,power);
    znew=TriplexAdditionPolynomial2XnZn1(znew,-z);
    znew=TriplexAdditionPolynomial2XnZn1(znew,c);
    z=znew;
}

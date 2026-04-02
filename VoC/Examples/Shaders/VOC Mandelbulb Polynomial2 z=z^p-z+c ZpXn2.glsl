vec3 TriplexAdditionPolynomial2ZpXn2(in vec3 z, in vec3 c) {
    vec3 znew;
    znew.x=z.x+c.x;
    znew.y=z.y+c.y;
    znew.z=z.z+c.z;
    return znew;
}

vec3 ZpXn2TriplexPowerPolynomial2ZpXn2(in vec3 z,in float p) {
    vec3 znew;
    radius=pow(radius,p);
    theta=theta*p;
    phi=phi*p;
    znew.x=radius*cos(phi)*-sin(theta);
    znew.y=radius*cos(phi)*cos(theta);
    znew.z=radius*-sin(phi);
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
    znew=ZpXn2TriplexPowerPolynomial2ZpXn2(z,power);
    znew=TriplexAdditionPolynomial2ZpXn2(znew,-z);
    znew=TriplexAdditionPolynomial2ZpXn2(znew,c);
    z=znew;
}

vec3 TriplexAdditionPolynomial1ZpXn3(in vec3 z, in vec3 c) {
    vec3 znew;
    znew.x=z.x+c.x;
    znew.y=z.y+c.y;
    znew.z=z.z+c.z;
    return znew;
}

vec3 ZpXn3TriplexPowerPolynomial1ZpXn3(in vec3 z,in float p) {
    vec3 znew;
    radius=pow(radius,p);
    theta=theta*p;
    phi=phi*p;
    znew.x=radius*sin(phi)*-sin(theta);
    znew.y=radius*cos(theta)*sin(phi);
    znew.z=radius*cos(phi);
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
    znew=ZpXn3TriplexPowerPolynomial1ZpXn3(z,power);
    znew=TriplexAdditionPolynomial1ZpXn3(znew,z);
    znew=TriplexAdditionPolynomial1ZpXn3(znew,c);
    z=znew;
}

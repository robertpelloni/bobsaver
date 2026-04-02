vec3 TriplexAdditionMandelbulbYpZn2(in vec3 z, in vec3 c) {
    vec3 znew;
    znew.x=z.x+c.x;
    znew.y=z.y+c.y;
    znew.z=z.z+c.z;
    return znew;
}

vec3 YpZn2TriplexPowerMandelbulbYpZn2(in vec3 z,in float p) {
    vec3 znew;
    radius=pow(radius,p);
    theta=theta*p;
    phi=phi*p;
    znew.x=radius*sin(phi)*cos(theta);
    znew.y=radius*cos(phi);
    znew.z=radius*-sin(theta)*sin(phi);
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
    znew=YpZn2TriplexPowerMandelbulbYpZn2(z,power);
    znew=TriplexAdditionMandelbulbYpZn2(znew,c);
    z=znew;
}

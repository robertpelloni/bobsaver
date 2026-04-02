vec3 TriplexAdditionMandelbulbYnXn3(in vec3 z, in vec3 c) {
    vec3 znew;
    znew.x=z.x+c.x;
    znew.y=z.y+c.y;
    znew.z=z.z+c.z;
    return znew;
}

vec3 YnXn3TriplexPowerMandelbulbYnXn3(in vec3 z,in float p) {
    vec3 znew;
    radius=pow(radius,p);
    theta=theta*p;
    phi=phi*p;
    znew.x=radius*cos(phi)*-sin(theta);
    znew.y=radius*sin(phi);
    znew.z=radius*cos(theta)*cos(phi);
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
    znew=YnXn3TriplexPowerMandelbulbYnXn3(z,power);
    znew=TriplexAdditionMandelbulbYnXn3(znew,c);
    z=znew;
}

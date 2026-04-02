vec3 TriplexAdditionIkenagaZnYn3(in vec3 z, in vec3 c) {
    vec3 znew;
    znew.x=z.x+c.x;
    znew.y=z.y+c.y;
    znew.z=z.z+c.z;
    return znew;
}

vec3 TriplexPowerIkenagaZnYn3(in vec3 z,in float p) {
    vec3 znew;
    radius=pow(radius,p);
    theta=theta*p;
    phi=phi*p;
    znew.x=radius*sin(phi)*-cos(theta);
    znew.y=radius*sin(phi)*sin(theta);
    znew.z=radius*cos(phi);
    return znew;
}

vec3 TriplexMultiplicationIkenagaZnYn3(in vec3 z,in vec3 p){
    float r1,r2,r1r2,theta1,theta2,phi1,phi2;
    vec3 znew;
    r1=length(z);
    r2=length(p);
    r1r2=r1*r2;
    theta1=atan(z.y,z.x);
    theta2=atan(p.y,p.x);
    phi1=asin(z.z/r1);
    phi2=asin(p.z/r2);
    znew.x=r1r2*sin(phi1+phi2)*-cos(theta1+theta2);
    znew.y=r1r2*sin(phi1+phi2)*sin(theta1+theta2);
    znew.z=r1r2*cos(phi1+phi2);
    return znew;
}

void Iterate(inout vec3 z,in vec3 c) {
    vec3 znew,znew2;
    theta=atan(z.y,z.x);
    phi=asin(z.z/radius)+phase;
    if (firstiteration==1) {
        theta=theta*thetascale;
        phi=phi*phiscale;
    }
    znew=TriplexPowerIkenagaZnYn3(z,power);
	znew2=c-vec3(1.0,1.0,1.0);
	znew2=TriplexMultiplicationIkenagaZnYn3(znew2,z);
	znew2=znew2-c;
	znew=znew+znew2;
	lastz=z;
	z=znew;
}

vec3 TriplexMultiplicationIkenagaTrigRule412(in vec3 z,in vec3 p) {
     vec3 znew;
     float r1,r2,r1r2,theta1,theta2,phi1,phi2,cosph;
     r1=length(z);
     r2=length(p);
     r1r2=r1*r2;
     theta1=atan(z.y,z.x);
     theta2=atan(p.y,p.x);
     phi1=asin(z.z/r1);
     phi2=asin(p.z/r2);
     znew.x=r1r2*sin(theta1+theta2);
     znew.y=r1r2*-cos(theta1+theta2);
     znew.z=r1r2*sin(phi1+phi2);
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
     radius=pow(radius,power);
     if (radius==0) { radius=0.00001; }
     theta=theta*power;
     phi=phi*power;
     znew.x=radius*sin(theta);
     znew.y=radius*-cos(theta);
     znew.z=radius*sin(phi);
	znew2=c-vec3(1.0,1.0,1.0);
	znew2=TriplexMultiplicationIkenagaTrigRule412(znew2,z);
	znew2=znew2-c;
	znew=znew+znew2;
	lastz=z;
	z=znew;
}

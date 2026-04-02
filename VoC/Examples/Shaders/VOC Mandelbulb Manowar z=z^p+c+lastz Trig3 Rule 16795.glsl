void Iterate(inout vec3 z,in vec3 c) {
vec3 znew;
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
znew.x=radius*sin(phi);
znew.y=radius*cos(phi)*sin(theta);
znew.z=radius*-cos(theta)*-cos(theta);
	znew=znew+c;
	znew=znew+lastz;
	lastz=z;
	z=znew;
}

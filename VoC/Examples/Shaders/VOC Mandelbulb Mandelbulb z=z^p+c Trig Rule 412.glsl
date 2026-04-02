void Iterate(inout vec3 z,in vec3 c) {
vec3 znew;
theta=atan(z.y,z.x);
phi=asin(z.z/radius)+phase;
if (firstiteration==1) {
    theta=theta*thetascale;
    phi=phi*phiscale;
}
radius=pow(radius,power);
theta=theta*power;
phi=phi*power;
z.x=radius*sin(theta);
z.y=radius*-cos(theta);
z.z=radius*sin(phi);
z+=c;
}

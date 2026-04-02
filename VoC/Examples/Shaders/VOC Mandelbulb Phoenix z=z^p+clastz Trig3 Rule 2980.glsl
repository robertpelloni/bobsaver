vec3 TriplexMultiplicationPhoenixTrig3Rule2980(in vec3 z,in vec3 p) {
     vec3 znew;
     float r1,r2,r1r2,theta1,theta2,phi1,phi2,cosph;
     r1=length(z);
     r2=length(p);
     r1r2=r1*r2;
     theta1=atan(z.y,z.x);
     theta2=atan(p.y,p.x);
     phi1=asin(z.z/r1);
     phi2=asin(p.z/r2);
     znew.x=r1r2*cos(phi1+phi2);
     znew.y=r1r2*-sin(phi1+phi2)*sin(theta1+theta2);
     znew.z=r1r2*sin(phi1+phi2)*sin(phi1+phi2);
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
     znew.x=radius*cos(phi);
     znew.y=radius*-sin(phi)*sin(theta);
     znew.z=radius*sin(phi)*sin(phi);
     znew2=TriplexMultiplicationPhoenixTrig3Rule2980(c,lastz);
     znew=znew+znew2;
     lastz=z;
     z=znew;
}

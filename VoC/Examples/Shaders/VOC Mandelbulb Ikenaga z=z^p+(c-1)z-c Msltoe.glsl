// z+c
vec3 TriplexAdditionIkenagaMsltoe(in vec3 z, in vec3 c) {
	vec3 znew;
    znew.x=z.x+c.x;
    znew.y=z.y+c.y;
    znew.z=z.z+c.z;
	return znew;
}

vec3 MsltoeTriplexPowerIkenagaMsltoe(in vec3 z, in float p) {
	vec3 znew;
    radius=pow(radius,p);
    theta=theta*p;
    phi=phi*p;
    if (z.z*z.z<z.y*z.y) {
         znew.x=radius*cos(theta)*cos(phi);
         znew.y=radius*sin(theta)*cos(phi);
         znew.z=-radius*sin(phi);
	} else {
         znew.x=radius*cos(theta)*cos(phi);
         znew.y=-radius*sin(phi);
         znew.z=radius*sin(theta)*cos(phi);
    }
	return znew;
}

vec3 TriplexMultiplicationIkenagaMsltoe(in vec3 z,in vec3 p) {
     vec3 znew;
     float r1,r2,r1r2,theta1,theta2,phi1,phi2,cosph;
     r1=length(z);
     r2=length(p);
     r1r2=r1*r2;
     theta1=atan(z.y,z.x);
     theta2=atan(p.y,p.x);
     phi1=asin(z.z/r1);
     phi2=asin(p.z/r2);
     cosph=r1r2*cos(phi1+phi2);
     znew.x=cosph*cos(theta1+theta2);
     znew.y=cosph*sin(theta1+theta2);
     znew.z=r1r2*sin(phi1+phi2);
     return znew;
}


void Iterate(inout vec3 z,in vec3 c) {
	vec3 znew,znew2;
    if (z.z*z.z<z.y*z.y) {
         theta=atan(z.y,z.x);
         phi=asin(z.z/radius)+phase;
	} else {
         theta=atan(z.z,z.x);
         phi=asin(z.y/radius)+phase;
    }

    if (firstiteration==1) {
         theta=theta*thetascale;
         phi=phi*phiscale;
    }

    // ^p
    znew=MsltoeTriplexPowerIkenagaMsltoe(z,power);
	znew2=c-vec3(1.0,1.0,1.0);
	znew2=TriplexMultiplicationIkenagaMsltoe(znew2,z);
	znew2=znew2-c;
	znew=znew+znew2;
	lastz=z;
	z=znew;
}

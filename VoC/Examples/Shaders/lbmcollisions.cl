__kernel void LBMCollisionsKernel( __global double * n0,
							       __global double * nN,
							       __global double * nS,
							       __global double * nE,
							       __global double * nW,
							       __global double * nNE,
							       __global double * nNW,
							       __global double * nSE,
							       __global double * nSW,
							       __global double * density,
							       __global double * xvel,
							       __global double * yvel,
							       __global double * speed2,
							       __global double * barrier,
							       __global double * omega)
{	
	int index=get_global_id(0);
    if (barrier[index]<0.5) {
		double n=n0[index]+nN[index]+nS[index]+nE[index]+nW[index]+nNW[index]+nNE[index]+nSW[index]+nSE[index];
		density[index]=n;
		double one9th=1.0/9.0;
		double one36th=1.0/36.0;
		double one9thn=one9th*n;
		double one36thn=one36th*n;
		double four9ths=4.0/9.0;
		double vx=0.0;
		double vy=0.0;
		if (n>0) { vx=(nE[index]+nNE[index] + nSE[index] - nW[index] - nNW[index] - nSW[index]) / n; } else { vx=0; }
		xvel[index] = vx;
		if (n>0) { vy= (nN[index] + nNE[index] + nNW[index] - nS[index] - nSE[index] - nSW[index]) / n;	} else { vy=0; }
		yvel[index] = vy;	
		double vx3 = 3.0 * vx;
		double vy3 = 3.0 * vy;
		double vx2 = vx * vx;
		double vy2 = vy * vy;
		double vxvy2 = 2.0 * vx * vy;
		double v2 = vx2 + vy2;
		speed2[index] = v2;
		double v215 = 1.5 * v2;
		n0[index]=n0[index]   + omega[index] * (four9ths*n * (1.0                              - v215) - n0[index]);
		nE[index]=nE[index]   + omega[index] * (   one9thn * (1.0 + vx3       + 4.5*vx2        - v215) - nE[index]);
		nW[index]=nW[index]   + omega[index] * (   one9thn * (1.0 - vx3       + 4.5*vx2        - v215) - nW[index]);
		nN[index]=nN[index]   + omega[index] * (   one9thn * (1.0 + vy3       + 4.5*vy2        - v215) - nN[index]);
		nS[index]=nS[index]   + omega[index] * (   one9thn * (1.0 - vy3       + 4.5*vy2        - v215) - nS[index]);
		nNE[index]=nNE[index] + omega[index] * (  one36thn * (1.0 + vx3 + vy3 + 4.5*(v2+vxvy2) - v215) - nNE[index]);
		nNW[index]=nNW[index] + omega[index] * (  one36thn * (1.0 - vx3 + vy3 + 4.5*(v2-vxvy2) - v215) - nNW[index]);
		nSE[index]=nSE[index] + omega[index] * (  one36thn * (1.0 + vx3 - vy3 + 4.5*(v2-vxvy2) - v215) - nSE[index]);
		nSW[index]=nSW[index] + omega[index] * (  one36thn * (1.0 - vx3 - vy3 + 4.5*(v2+vxvy2) - v215) - nSW[index]);
	}
}

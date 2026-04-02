uniform vec2 resolution;
uniform vec3 palette[256];

out vec4 glFragColor;

double sqrsamplepixels=double(samplepixels*samplepixels);
double bailout_squared=double(bailout*bailout);
double magnitude,r1,r2,g1,g2,b1,b2,tweenval;
float realiters;
vec4 finalcol,col;
int superx,supery;
double stepx=(xmax-xmin)/resolution.x/double(samplepixels);
double stepy=(ymax-ymin)/resolution.y/double(samplepixels);
int index,colval,colval2;
dvec2 z,c,dz;
double x,y,dist;

const float PI = 3.1415926535897932384626433832795;

void main(void)
{
	finalcol=vec4(0,0,0,0);
	for (supery=0;supery<samplepixels;supery++)
	{
		for (superx=0;superx<samplepixels;superx++)
		{
			c.x = xmin+gl_FragCoord.x/resolution.x*(xmax-xmin)+(stepx*double(superx));
			c.y = ymax-gl_FragCoord.y/resolution.y*(ymax-ymin)+(stepy*double(supery));
			int i;
			z = dvec2(0.0,0.0);
			dz = dvec2(0.0,0.0);

			for(i=0; i<maxiters; i++) 
			{
				if (displaystyle==3) {
					if(magnitude>bailout_squared) break;
					//distance estimator z derivative
					// Z' -> 2·Z·Z' + 1
					dz = 2.0*vec2(z.x*dz.x-z.y*dz.y, z.x*dz.y + z.y*dz.x) + vec2(1.0,0.0);					 
				}

				//START OF FRACTAL FORMULA
				x = (z.x * z.x - z.y * z.y) + c.x;
				y = (z.y * z.x + z.x * z.y) + c.y;
				//END OF FRACTAL FORMULA
			
				magnitude=(x * x + y * y);
			
				if (displaystyle<3) {
					if(magnitude>bailout_squared) break;
				}
			
				z.x = x;
				z.y = y;
			}

			if (i==maxiters) {
				col=vec4(0.0,0.0,0.0,1.0);
			} else {
				//iteration bands
				if (displaystyle==0) {
					colval=int(mod(i,255));
					r1=palette[colval].r;
					g1=palette[colval].g;
					b1=palette[colval].b;
					col=vec4(r1,g1,b1,1.0);
				}
				//CPM smooth colors
				if (displaystyle==1) {
					//note that double precision does not support log so it needs to be cast as float
					realiters=float(i+1-((log(log(sqrt(float(magnitude))))/log(2.0))));
					colval=int(mod(realiters,255));
					colval2=int(mod(colval+1,255));
					tweenval=realiters-int(realiters);
					r1=palette[colval].r;
					g1=palette[colval].g;
					b1=palette[colval].b;
					r2=palette[colval2].r;
					g2=palette[colval2].g;
					b2=palette[colval2].b;
					col=vec4(r1+((r2-r1)*tweenval),g1+((g2-g1)*tweenval),b1+((b2-b1)*tweenval),1.0);
				}
				//decomposition
				if (displaystyle==2) {
                    colval=int((atan(float(z.y),float(z.x))+PI)/PI*2*256);
                    colval=int(mod(colval,255));
					r1=palette[colval].r;
					g1=palette[colval].g;
					b1=palette[colval].b;
					col=vec4(r1,g1,b1,1.0);
				}
				//distance estimation
				if (displaystyle==3) {
					
					if (i<maxiters) {
						//dist=log(float(module*module))*module/sqrt(dxn*dxn+dyn*dyn)*zoomfactor;
						// distance estimation: G/|G'|
						//dist=sqrt(magnitude/(x*x+y*y))*0.5*log(float(magnitude));
						dist = 0.5*sqrt(dot(z,z)/dot(dz,dz))*log(float(dot(z,z)))*zoomfactor;
                        
						if (dist<0.01) {
                            colval=int(255*dist/0.01);
                            r1=palette[colval].r;
                            g1=palette[colval].g;
                            b1=palette[colval].b;
							col=vec4(r1,g1,b1,1.0);
						}

                        if (dist<0) {
							col=vec4(0.0,0.0,0.0,1.0);
						}

                        if (dist>=0.01) {
                            r1=palette[255].r;
                            g1=palette[255].g;
                            b1=palette[255].b;
							col=vec4(r1,g1,b1,1.0);
						}
						

					} else {
						col=vec4(0.0,0.0,0.0,0.0); //0 alpha to indicate "in the void"
					}
				
					//col=vec4(dist,dist,dist,1.0);
				
				
				}
			}

			finalcol+=col;
		}
	}
	glFragColor = vec4(finalcol/double(sqrsamplepixels));
}
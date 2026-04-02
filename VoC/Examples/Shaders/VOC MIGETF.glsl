#version 400

const int samplepixels=1;
const double bodygravity[7] = double[] (0.8,0.8,0.8,0.8,0.8,0.8,0.8);
const double bodyypositions[7] = double[] (-0.700,-0.436,0.156,0.631,0.631,0.156,-0.436);
const double bodyxpositions[7] = double[] (0.000,0.547,0.682,0.304,-0.304,-0.682,-0.547);
const int numstars = 7;
const double escrad = 2;
const int maxiterations = 256;
const double inertiacontrib = -0.95;
const double exponent = 2.5;
const double ymax = -0.907273;
const double ymin = -3.092727;
const double xmax = 1.84437777777779;
const double xmin = -1.9277111111111;

//uniforms passed in from Visions of Chaos
uniform vec2 resolution;
uniform vec3 palette[256];

double sqrsamplepixels=double(samplepixels*samplepixels);
vec4 finalcol,col;
int colval;
int superx,supery,iters;
double xp,yp,r,r2,rx,ry,gmr;
double px,py,ax,ay,vx,vy,g,ix,iy;
double deltax,deltay;
double cxpos,cypos,cxacc,cyacc,cxvel,cyvel,cdt,dx,dy,f;
float realiters;
int index,colval2;
double r1,g1,b1,g2,b2,tweenval;

double pxtmp,pytmp,axtmp,aytmp,vxtmp,vytmp;

void main(void) {

	double stepx=(xmax-xmin)/resolution.x/double(samplepixels);
	double stepy=(ymax-ymin)/resolution.y/double(samplepixels);

	double escrad2 = escrad*escrad;
	
    finalcol=vec4(0,0,0,0);
    for (supery=0;supery<samplepixels;supery++)
    {
        for (superx=0;superx<samplepixels;superx++)
        {
            //particle start position in world coordinates
			xp = xmin+gl_FragCoord.x/resolution.x*(xmax-xmin)+(stepx*double(superx));
            // ymax- flips y coordinates as Visions of Chaos uses top left origin for coordinates
            yp = ymax-gl_FragCoord.y/resolution.y*(ymax-ymin)+(stepy*double(supery));

            //set record for comet
            cxpos=xp;
            cypos=yp;
            cxacc=0;
            cyacc=0;
            cxvel=0;
            cyvel=0;
            iters = 0;	//variable to keep track of iterations after loop
			ix=0;
			iy=0;
			
			for (int i=1;i<=maxiterations;i++) {

				if (cxpos*cxpos+cypos*cypos>escrad2) { break;}

				iters = i;
				
                //calc pull of objects
                px=0;
                py=0;
                // for each body, caclulate the pull and add it to the summed pull vector
				for (int loop=0;loop<numstars;loop++) {
					// calc pull vector between comet and body
                    dx=bodyxpositions[loop]-cxpos;
                    dy=bodyypositions[loop]-cypos;
			        // get the distance, and normalize the pull vector
                    f=sqrt(dx*dx+dy*dy);
                    dx=dx/f;
                    dy=dy/f;
                    // scale difference vector by G of the body
                    g=bodygravity[loop];
                    dx=dx*g;
                    dy=dy*g;
                    // add pre-addition value (1 for EXP_PRE1, 0 otherwise)
                    // f=f+0;
                    // calculate the exponential, i.e. (x^N), for dividing the distance
                    f=pow(float(f),float(exponent));
                    // add post-addition value (1 for EXP_POST1, 0 otherwise)
                    // f=f+0;
                    // divide pull by distance function
                    dx=dx/f;
                    dy=dy/f;
                    //accumulate pull
                    px=px+dx;
                    py=py+dy;
				}
                //multiply inertia (velocity) by inertia contribution
                ix=ix*inertiacontrib;
                iy=iy*inertiacontrib;
                //add pull to inertia (velocity)
                ix=ix+px;
                iy=iy+py;
                // add inertia to comet to get new position
                cxpos=cxpos+ix;
                cypos=cypos+iy;
			}
							  
            if (iters==maxiterations) {
				col=vec4(0.0,0.0,0.0,1.0);
			} else {
				//colval=int(mod(iters,256));
				//col=vec4(palette[colval],1.0);
				
				//CPM smooth colors
				//note that double precision does not support log so it needs to be cast as float
				realiters=float(iters+1-((log(log(sqrt(float(cxpos*cxpos+cypos*cypos))))/log(2.0))));
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
            finalcol+=col;
        }
    }
    gl_FragColor = vec4(finalcol/double(sqrsamplepixels));
}

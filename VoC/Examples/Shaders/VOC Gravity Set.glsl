#version 400

const int samplepixels=1;
const double starmasses[5] = double[] (100000,100000,100000,100000,100000);
const double starypositions[5] = double[] (-100,-30,80,80,-30);
const double starxpositions[5] = double[] (0,95,58,-58,-95);
const int numstars = 5;
const double escrad = 100000;
const double escvel = 0;
const int maxiterations = 256;
const double gravity = 1.36;
const double deltatime = 6.5;
const double initialy = 0;
const double initialx = 0;
const double ymax = -0.97;
const double ymin = -3.03;
const double xmax = 1.73611111111112;
const double xmin = -1.81944444444444;

//uniforms passed in from Visions of Chaos
uniform vec2 resolution;
uniform vec3 palette[256];

out vec4 glFragColor;

double sqrsamplepixels=double(samplepixels*samplepixels);
vec4 finalcol,col;
int colval;
int superx,supery,iters;
double xp,yp,r,r2,rx,ry,gmr;
double px,py,ax,ay,vx,vy,dt,g;
double deltax,deltay;

double pxtmp,pytmp,axtmp,aytmp,vxtmp,vytmp;

void main(void) {

	double stepx=(xmax-xmin)/resolution.x/double(samplepixels);
	double stepy=(ymax-ymin)/resolution.y/double(samplepixels);

	double escrad2 = escrad*escrad;
	double escvel2 = escvel*escvel;
	
    finalcol=vec4(0,0,0,0);
    for (supery=0;supery<samplepixels;supery++)
    {
        for (superx=0;superx<samplepixels;superx++)
        {
            //particle start position in world coordinates
			xp = xmin+gl_FragCoord.x/resolution.x*(xmax-xmin)+(stepx*double(superx));
            // ymax- flips y coordinates as Visions of Chaos uses top left origin for coordinates
            yp = ymax-gl_FragCoord.y/resolution.y*(ymax-ymin)+(stepy*double(supery));

            //moving particle
			px = xp; 		//moving particle start position
			py = yp; 		//moving particle start position
			ax = 0; 		//particle acceleration
			ay = 0; 		//particle acceleration
			vx = initialx; 	//particle initial velocity
			vy = initialy; 	//particle initial velocity
			dt = deltatime; //delta time
			g = gravity; 	//gravity constant
			
			iters = 0;	//variable to keep track of iterations after loop
			
			for (int i=1;i<=maxiterations;i++) {

				iters = i;
				
				pxtmp = px;
				pytmp = py;
				axtmp = ax;
				aytmp = ay;
				vxtmp = vx;
				vytmp = vy;
				
				// sum the accelerational forces of all stars
				for (int loop=0;loop<numstars;loop++) {
					rx = pxtmp - starxpositions[loop];
                    ry = pytmp - starypositions[loop];
                    r2 = rx * rx + ry * ry;
                    r = sqrt(r2);
                    gmr = -g*starmasses[loop]/r2;
                    axtmp += gmr*rx/r;
                    aytmp += gmr*ry/r;
				}
				vx = vxtmp + axtmp * dt;
				vy = vytmp + aytmp * dt;
				px = pxtmp + vxtmp * dt;
				py = pytmp + vytmp * dt;
				
			
				if (escrad2>0) {
					if (px*px+py*py>escrad2) {
						break;
					}
				}
				if (escvel2>0) {
					if (vx*vx+vy*vy>escvel2) {
						break;
					}
				}
				
			}

            if (iters==maxiterations) {
				col=vec4(0.0,0.0,0.0,1.0);
			} else {
				colval=int(mod(iters,256));
				col=vec4(palette[colval],1.0);
			}
            finalcol+=col;
        }
    }
    glFragColor = vec4(finalcol/double(sqrsamplepixels));
}

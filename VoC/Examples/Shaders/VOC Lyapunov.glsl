#version 400
const int rulestring[200] = int[] (1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0);
const int samplepixels=3;
const int nlyap=200;
const int init=100;
const double xstart=0.1;
uniform double ymax=5.15;
uniform double ymin=-5.15;
uniform double xmax=8.88888888888889;
uniform double xmin=-8.88888888888889;
uniform vec2 resolution;
uniform vec3 palette[256];

out vec4 glFragColor;

double sqrsamplepixels=double(samplepixels*samplepixels);
vec4 finalcol,col;
int colval;
int superx,supery;

const double log2=log(2.0);

double CalculateLyapunovExponent(in double xstart, in double aval, in double bval, in int init, in int nlyap) {
    double x,total,a,b,tmp;
    int i;
    a=aval;
    b=bval;
    x=xstart;
    for (i=0;i<init;i++) {
         if (rulestring[i]==0) {
            x=a*x*(1.0-x);
        } else {
             x=b*x*(1.0-x);
        }
    }
    total=0.0;

    for (i=0;i<nlyap;i++) {
    
         if (rulestring[i]==0) {
              x=a*x*(1.0-x);
              tmp=abs(a-2.0*a*x);
              if (tmp==0) { tmp=0.00001; }
              total=total+log(float(tmp))/log2;
         } else {
              x=b*x*(1.0-x);
              tmp=abs(b-2.0*b*x);
              if (tmp==0) { tmp=0.00001; }
              total=total+log(float(tmp))/log2;
         }
    }
    return total/double(nlyap);
}


void main(void) {
	double adist,bdist,adiff,bdiff,aval,bval,lval;

	adist=xmax-xmin;
	bdist=ymax-ymin;
	adiff=adist/resolution.x;
	bdiff=bdist/resolution.y;

	double stepx=(xmax-xmin)/resolution.x/double(samplepixels);
	double stepy=(ymax-ymin)/resolution.y/double(samplepixels);

    finalcol=vec4(0,0,0,0);
    for (supery=0;supery<samplepixels;supery++)
    {
        for (superx=0;superx<samplepixels;superx++)
        {
            aval = xmin+gl_FragCoord.x/resolution.x*(xmax-xmin)+(stepx*double(superx));
            // ymax- flips y coordinates as Visions Of Chaos uses top left origin for coordinates
            bval = ymax-gl_FragCoord.y/resolution.y*(ymax-ymin)+(stepy*double(supery));
            int i;

			lval=CalculateLyapunovExponent(xstart,aval,bval,init,nlyap);
            //values less than 0 are non-chaotic regions, and are
            //shaded according to value. other pixels are left black
            if (lval<0.0) {
				//colval:=trunc(64*abs(lval))mod 256;
				colval=int(mod(64.0*abs(lval),256));
				col=vec4(palette[colval],1.0);
			} else {
				col=vec4(0.0,0.0,0.0,1.0);
			}
            finalcol+=col;
        }
    }
    glFragColor = vec4(finalcol/double(sqrsamplepixels));
}

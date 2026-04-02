uniform vec2 resolution;
uniform vec3 palette[256];

float sqrsamplepixels=float(samplepixels*samplepixels);
vec4 finalcol,col;
int colval;
int superx,supery;

const float log2=log(2.0);

float CalculateLyapunovExponent(in float xstart, in float aval, in float bval, in int init, in int nlyap) {
    float x,total,a,b,tmp;
    int i;
    a=aval;
    b=bval;
    x=xstart;
    for (i=1;i<init;i++) {
         if (rulestring[i]==0) {
            x=a*x*(1.0-x);
        } else {
             x=b*x*(1.0-x);
        }
    }
    total=0.0;

    for (i=1;i<nlyap;i++) {
    
         if (rulestring[i]==0) {
              x=a*x*(1.0-x);
              tmp=abs(a-2.0*a*x);
              if (tmp==0) { tmp=0.00001; }
              total=total+log(tmp)/log2;
         } else {
              x=b*x*(1.0-x);
              tmp=abs(b-2.0*b*x);
              if (tmp==0) { tmp=0.00001; }
              total=total+log(tmp)/log2;
         }
    }
    return total/float(nlyap);
}


void main(void) {
	float adist,bdist,adiff,bdiff,aval,bval,lval;

	adist=xmax-xmin;
	bdist=ymax-ymin;
	adiff=adist/resolution.x;
	bdiff=bdist/resolution.y;

	float stepx=(xmax-xmin)/resolution.x/float(samplepixels);
	float stepy=(ymax-ymin)/resolution.y/float(samplepixels);

    finalcol=vec4(0,0,0,0);
    for (supery=0;supery<samplepixels;supery++)
    {
        for (superx=0;superx<samplepixels;superx++)
        {
            aval = xmin+gl_FragCoord.x/resolution.x*(xmax-xmin)+(stepx*float(superx));
            // ymax- flips y coordinates as Visions Of Chaos uses top left origin for coordinates
            bval = ymax-gl_FragCoord.y/resolution.y*(ymax-ymin)+(stepy*float(supery));
            int i;

			lval=CalculateLyapunovExponent(xstart,aval,bval,init,nlyap);
            //values less than 0 are non-chaotic regions, and are
            //shaded according to value. other pixels are left black
            if (lval<0.0) {
				//colval:=trunc(64*abs(lval))mod 256;
				colval=int(mod(int(64.0*abs(lval)),256.0));
				//col=vec4(abs(lval),abs(lval),abs(lval),1.0);
				col=vec4(palette[colval],1.0);
			} else {
				col=vec4(0.0,0.0,0.0,1.0);
			}
            finalcol+=col;
        }
    }
    gl_FragColor = vec4(finalcol/float(sqrsamplepixels));
}

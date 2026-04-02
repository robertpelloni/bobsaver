#version 420

//the following uniform values are set by Visions Of Chaos prior to shader execution
uniform vec2 resolution;
uniform vec3 palette[256];
uniform float xmin;
uniform float xmax;
uniform float ymin;
uniform float ymax;
uniform int maxiters;

out vec4 glFragColor;

//supersampling amount
const int samplepixels=1;

float sqrsamplepixels=float(samplepixels*samplepixels);
vec4 finalcol,col;
int superx,supery;

int rulestring[2048]; //0 = A - 1 = B in rulestring - maximum (init+nlyap) cannot be >2048

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
              //if (tmp==0) { tmp=0.0000001; }
              total=total+log(tmp)/log2;
         } else {
              x=b*x*(1.0-x);
              tmp=abs(b-2.0*b*x);
              //if (tmp==0) { tmp=0.0000001; }
              total=total+log(tmp)/log2;
         }
    }
    return total/float(nlyap);
}

void main(void) {
    float adist,bdist,adiff,bdiff,aval,bval,xstart,lval;
    float xmin,xmax,ymin,ymax;
    int init,nlyap;

    xmin=-5.0;
    xmax=5.0;
    ymin=-5.0;
    ymax=5.0;
    xstart=0.1;
    init=100;
    nlyap=200;

    adist=xmax-xmin;
    bdist=ymax-ymin;
    adiff=adist/resolution.x;
    bdiff=bdist/resolution.y;

    float stepx=(xmax-xmin)/resolution.x/float(samplepixels);
    float stepy=(ymax-ymin)/resolution.y/float(samplepixels);

    //fill the rulestring array
    for (int i=0;i<2048;i++) {
        if (mod(float(i),2.0)==0.0) { rulestring[i]=1; } else { rulestring[i]=0; }
    }

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
                col=vec4(abs(lval),abs(lval),abs(lval),1.0);
            } else {
                col=vec4(0.0,0.0,0.0,1.0);
            }
            finalcol+=col;
        }
    }
    glFragColor = vec4(finalcol/float(sqrsamplepixels));
}

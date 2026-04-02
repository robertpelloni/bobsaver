#version 420

// bifurcation diagrams

uniform vec2 resolution;
uniform float time;
uniform sampler2D backbuffer;

out vec4 glFragColor;

//unremark which formula you want to generate
const bool logistic=false;
const bool henon=false;
const bool delayedlogistic=false;
const bool bouncingball=true;

const float piover180=0.01745329;

float xmin,xmax,ymin,ymax;
int iters,skipiters;

float xn,xpos,ypos,dx,dy,henonmultiplier,xnew,ynew,xminus1,xminus2,slopedegrees,initialvelocity;
float a,u,z,cosa2,sin4a,tga,ctga,temp0,temp1,temp1a,temp2,temp3,temp4,temp5,sqrtz;
bool jumped;

float magnitude,realiters,r1,r2,g1,g2,b1,b2,tweenval;
vec4 finalcol,col;
int superx,supery,loop;
int index,colval,colval2;
float xp,yp,x,y;
int hitcount,ypixel;

void main(void)
{
    //set values for selected bifurcation type
    if (logistic==true) {
        xmin=1.0;
        xmax=4.0;
        ymin=0.0;
        ymax=1.0;
        iters=4000;
        skipiters=100;
    }

    if (henon==true) {
        xmin=0.0;
        xmax=1.4;
        ymin=-0.5;
        ymax=0.5;
        iters=4000;
        skipiters=100;
        henonmultiplier=0.3;
    }

    if (delayedlogistic==true) {
        xmin=1.99;
        xmax=2.271;
        ymin=0.0;
        ymax=1.0;
        iters=4000;
        skipiters=100;
    }

    if (bouncingball==true) {
        xmin=0.0;
        xmax=1.0;
        ymin=-1.0;
        ymax=1.0;
        iters=4000;
        skipiters=100;
        slopedegrees=60.0;
        initialvelocity=0.2;
    }

    dx=(xmax-xmin)/resolution.x;
    dy=(ymax-ymin)/resolution.y;

    finalcol=vec4(0,0,0,0);
    vec2 position = ( gl_FragCoord.xy / resolution.xy );
    //read the current pixel color from the back buffer
    vec4 me = texture2D(backbuffer, position);
    
            
    //////////////////////////////////////////////////////////////////////////////////////////////////
    // Logistic
    //////////////////////////////////////////////////////////////////////////////////////////////////
    
    if (logistic==true) {
        hitcount=0; 
        //initial values
        xn=0.1;
        //x coordinate along the x axis between xmin and xmax
        xpos=xmin+gl_FragCoord.x*dx;
        //iteration loop
        for (int loop=0;loop<4096;loop++)
        {
            xn=xpos*xn*(1.0-xn);
            //skip initial iterations so it settles down
            if (loop>skipiters) {
                ypos=(xn-ymin)/(ymax-ymin)*resolution.y;
                ypixel=int(ypos);
                //increment back buffer if the iteration hit current pixel
                if (float(ypixel)-float(gl_FragCoord.y)>0.0) {
                if (float(ypixel)-float(gl_FragCoord.y)<1.0) {
                hitcount++;
                }}

            }
            if (loop>iters) { break; }
        }
        col=me+vec4(float(hitcount)*0.003,float(hitcount)*0.003,float(hitcount)*0.003,1.0);            
    }
    
    //////////////////////////////////////////////////////////////////////////////////////////////////
    // Henon
    //////////////////////////////////////////////////////////////////////////////////////////////////
    
    if (henon==true) {
        hitcount=0; 
        //initial values
        x=1.0;
        y=1.0;
        //x coordinate along the x axis between xmin and xmax
        xpos=xmin+gl_FragCoord.x*dx;
        //iteration loop
        for (int loop=0;loop<4096;loop++)
        {
            xnew=y+1.0-(xpos*x*x);
            ynew=henonmultiplier*x;
            x=xnew;
            y=ynew;
            //skip initial iterations so it settles down
            if (loop>skipiters) {
                ypos=(ynew-ymin)/(ymax-ymin)*resolution.y;
                ypixel=int(ypos);
                //increment back buffer if the iteration hit current pixel
                if (float(ypixel)-float(gl_FragCoord.y)>0.0) {
                if (float(ypixel)-float(gl_FragCoord.y)<1.0) {
                hitcount++;
                }}

            }
            if (loop>iters) { break; }
        }
        col=me+vec4(float(hitcount)*0.003,float(hitcount)*0.003,float(hitcount)*0.003,1.0);            
    }

    //////////////////////////////////////////////////////////////////////////////////////////////////
    // Delayed Logistic
    //////////////////////////////////////////////////////////////////////////////////////////////////
    
    if (delayedlogistic==true) {
        hitcount=0; 
        //initial values
        xn=0.1;
        xminus1=xn;
        xminus2=xn;
        //x coordinate along the x axis between xmin and xmax
        xpos=xmin+gl_FragCoord.x*dx;
        //iteration loop
        for (int loop=0;loop<4096;loop++)
        {
            xn=xpos*xminus1*(1.0-xminus2);
            xminus2=xminus1;
            xminus1=xn;
            //skip initial iterations so it settles down
            if (loop>skipiters) {
                ypos=(xn-ymin)/(ymax-ymin)*resolution.y;
                ypixel=int(ypos);
                //increment back buffer if the iteration hit current pixel
                if (float(ypixel)-float(gl_FragCoord.y)>0.0) {
                if (float(ypixel)-float(gl_FragCoord.y)<1.0) {
                hitcount++;
                }}

            }
            if (loop>iters) { break; }
        }
        col=me+vec4(float(hitcount)*0.003,float(hitcount)*0.003,float(hitcount)*0.003,1.0);            
    }
    

    //////////////////////////////////////////////////////////////////////////////////////////////////
    // Bouncing Ball
    //////////////////////////////////////////////////////////////////////////////////////////////////
    
    if (bouncingball==true) {
        hitcount=0; 
        //x coordinate along the x axis between xmin and xmax
        xpos=xmin+gl_FragCoord.x*dx;
        //initial values
        a=slopedegrees*piover180; //angle of slopes
        u=initialvelocity; //u initial velocity
        z=xpos;
        cosa2=cos(a)*cos(a);
        sin4a=sin(4.0*a);
        tga=tan(a);
        ctga=1.0/tan(a);
        jumped=false;
        temp0=sqrt(1.0-z);
        sqrtz=0.0;
        temp1=0.0;
        //iteration loop
        for (int loop=0;loop<4096;loop++)
        {
            if (jumped==false) {
                sqrtz=sqrt(z);
                temp1=sqrtz*tga;
            }
            jumped=false;
            temp2=2.0*temp1;
            temp3=u-temp2;
            if (temp3>=-temp0) {
                u=temp3; //stay on current slope
            } else {
                //jump to other slope
                temp4=0.5*sin4a;
                temp5=u*temp4;
                z=-z*(1.0+temp4*tga)+temp5*(-u*ctga+2.0*sqrtz)+2.0*cosa2;
                jumped=true;
                temp0=sqrt(1.0-z);
                sqrtz=sqrt(z);
                temp1a=temp1;
                temp1=sqrtz*tga;
                u=-u+temp1a-temp1;
            }
            //skip initial iterations so it settles down
            if (loop>skipiters) {
                ypos=(u-ymin)/(ymax-ymin)*resolution.y;
                ypixel=int(ypos);
                //increment back buffer if the iteration hit current pixel
                if (float(ypixel)-float(gl_FragCoord.y)>0.0) {
                if (float(ypixel)-float(gl_FragCoord.y)<1.0) {
                hitcount++;
                }}

            }
            if (loop>iters) { break; }
        }
        col=me+vec4(float(hitcount)*0.003,float(hitcount)*0.003,float(hitcount)*0.003,1.0);            
    }
                
    finalcol+=col;
    glFragColor = vec4(finalcol);
}

#version 420

// original https://www.shadertoy.com/view/XfByWW

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//constant for rotation
#define TAU 6.2831853

//Number of seconds per revolution, float
#define SCALE 10.
//Number of passes in main loop, int
#define PASSES 15
//Pixel threshold for dropout, float
#define SMALL 5.

//Colors (subject to change; we're doing a new pattern
#define C_BASE vec3(0.,0.,0.25)
#define C_DOT vec3(0.5,0.,1.)
#define C_HI1 vec3(1.,1.,1.)
#define C_HI2 vec3(0.,1.,1.)

//states for main loop
#define S_UNBOUND 0
#define S_INT_ROOT 1
#define S_EXT_CORNER 2
#define S_EXT_EDGE 3
#define S_GAP 4

vec2 cmult(vec2 p, vec2 q){return vec2(p.x*q.x-p.y*q.y,p.x*q.y+p.y*q.x);}

vec2 csqrt(vec2 a) {
    float r = length(a);
    float rpart = sqrt(0.5*(r+a.x));
    float ipart = sqrt(0.5*(r-a.x));
    if (a.y < 0.0) ipart = -ipart;
    return vec2(rpart,ipart);
}

vec3 cdt(in vec3 a, in vec3 b, in vec3 c, in bool pos){
    float z = 2.*sqrt(a.z*b.z+a.z*c.z+b.z*c.z)*(pos?1.:-1.);
    vec3 d = vec3(0.,0.,a.z+b.z+c.z+z);
    //Parallel lines have three solutions, and we can't handle that.
    if(a.z == 0.){
        vec3 d = vec3(0.,0.,b.z+c.z+2.*sqrt(b.z*c.z));
        //d.xy = (b.xy*b.z + c.xy*c.z)/(b.z+c.z);
        float sa = (b.z+c.z)/(b.z*c.z);
        float sb = (d.z+c.z)/(d.z*c.z);
        float sc = (d.z+b.z)/(d.z*b.z);
        float ss = (sa+sb+sc)/2.;
        float ta = sqrt(ss*(ss-sa)*(ss-sb)*(ss-sc));
        float th = ta/sa*2.;
        float bp = sqrt(sb*sb-th*th)/sa;
        d.xy = b.xy*bp+c.xy*(1.-bp);
        d.xy += (pos?1.:-1.)*(c.yx-b.yx)*vec2(1.,-1.)*ta/sa/sa*2.;
        //d.xy = d.xy + (c.yx-b.yx)*vec2(1.,-1.)*b.z*b.z*c.z*c.z*sqrt((d.z*b.z + d.z*c.z + b.z*c.z)/(d.z*d.z*b.z*b.z*c.z*c.z))/(b.z+c.z)/(b.z+c.z);
        return d;
    }
  
  
    if(d.z == 0.){
        //A line.  Can't find the center if it doesn't have one.
        return d;
    }
    if(z == 0.){
        //the easy way results in 0/0.  Time for the hard way.
        d.xy = (a.z*a.xy + b.z*b.xy + c.z*c.xy + 2.*csqrt(cmult(a.xy,b.xy)*a.z*b.z + cmult(a.xy,c.xy)*a.z*c.z + cmult(b.xy,c.xy)*b.z*c.z)*(pos?1.:-1.) )/d.z;
        return d;
    }
    float s = a.z+b.z+c.z+d.z;
    d.xy = -(a.z*a.xy*(2.*a.z-s)+b.z*b.xy*(2.*b.z-s)+c.z*c.xy*(2.*c.z-s))/(d.z*(2.*d.z-s));
    return d;
}

bool inTri(in vec3 a, in vec3 b, in vec3 c, in vec3 p) {
  a.z = 0.;
  b.z = 0.;
  c.z = 0.;
  p.z = 0.;
  a -= p;
  b -= p;
  c -=p;
  float u = cross(b, c).z;
  float v = cross(c, a).z;
  float w = cross(a, b).z;
  if (u*v < 0.) {
      return false;
  }
  if (u*w < 0.) {
      return false;
  }
  return true;
}

bool hitDot(in vec3 p, in vec3 a){
    return length(p.xy-a.xy)*a.z < 1.;
}

vec3 mapDot(in vec3 p, in vec3 a, in float oInv){
    p.xy = (p.xy-a.xy)*a.z;
    oInv *= a.z;
    float q = (1.-length(p.xy))/(abs(oInv)+0.05);
    q = 1.- (1.-q)*(smoothstep(1.0,0.9,length(p.xy)));
    p.z = min(p.z,sqrt(q)*1.05+.003);
    //p.z = sqrt(p.z*p.z+(1.-length(p.xy))/a.z);
    
    
    
    return p;
}

float proj(vec2 a, vec2 b){
    return dot(a,b)/dot(b,b);
}

vec3 roDot(vec3 a,float s){
    vec3 o = a;
    float ts = time*TAU/SCALE*s/2.;
    ts += (1.-cos(ts*12.))/8.;
    o.xy = cmult( a.xy, vec2( sin(ts) , cos(ts) ) );
    return o;
}

float distDot(in vec3 p, in vec3 a){
    return length(p.xy-a.xy)-1./a.z;
}

void main(void) {

    //vec3 for Reasons(TM)
    vec3 uvr = vec3((gl_FragCoord.xy-resolution.xy*0.5)*2./min(resolution.x,resolution.y),3.);

    int state = S_UNBOUND;
    
    //Aspect ratio, needed for rectangle splitting.
    float rr = resolution.x/resolution.y;
    
    //uvr += vec3(rr,1.,0.)*3.;
    //uvr.xy /= 4.;
    
    //Curvature of the last circle we passed through.
    float inv = 1.;

    //Bounding circles
    //(only pa is allowed to be non-positive on use, and pd/pe are for results)
    vec3 pa = vec3(0.);
    vec3 pb = vec3(0.);
    vec3 pc = vec3(0.);
    vec3 pd = vec3(0.);
    vec3 pe = vec3(0.);
    
    float pdm,dir; //used in some flows.
    
    
    vec3 backoff = uvr;
    float oinv = inv;
    
    for(int i=0;i<PASSES;i++){
        if(abs(inv)*SMALL > min(resolution.x,resolution.y)){
            break;
        }
        backoff = uvr;
        oinv = inv;
        switch (state) {
            case S_UNBOUND: //we're out in the wild somewhere, let's find out where
                //Always landscape, just to be sure.
                if(rr < 1.){
                    //rotate 90deg and flip aspect ratio.
                    uvr = uvr.yxz * vec3(1.,-1.,1.);
                    rr = 1./rr;
                }
                
                //number of squares we can fit in here
                //(with a 5% fudge factor)
                float spans = floor(rr+0.05);
                //size of our leftover chunks
                float wings = (rr-spans)/2.;
                
                //check to see if we're outside the square bounds
                if (abs(uvr.x) > spans){
                    //if yes, zoom into that wing and repeat.
                    uvr.x -= (spans+wings)*sign(uvr.x);
                    uvr.xy /= wings;
                    inv /= wings;
                    rr = wings;
                    //state is still unbound, no need to change.
                    break;
                }else{
                    if(spans-abs(uvr.x) > 1.){
                        state = S_EXT_EDGE;
                        //we'll need to define bounds after resolving to a square.
                    }else{
                        //Corner has known bounds.  Don't bother setting them.
                        state = S_EXT_CORNER;
                    }
                    //resolve to square.
                    uvr.x = fract( (uvr.x+spans)/2. )*2.-1.;
                    //if we're in a main circle, update state.
                    if(length(uvr.xy) < 1.){
                        state = S_INT_ROOT;
                        pa = vec3(0.,0.,-1.);
                        pb = vec3(0.,-0.5,2.);
                        pc = vec3(0.,0.5,2.);
                        uvr = roDot(uvr,inv);
                    }else if(state == S_EXT_EDGE){
                        //Probably don't need this, but just in case...
                        pa = vec3(0.);
                        //Main circle and one off to one side.
                        pb = vec3(0.,0.,1.);
                        pc = vec3(2.*sign(uvr.x),0.,1.);
                    }
                    
                    
                }

                
                
                break;
            case S_INT_ROOT: //Inside a circle but we haven't done anything yet.
                //Check B and C (we know we're in A)
                //Root-to-root requires no state change
                if(hitDot(uvr,pb)){
                    uvr = mapDot(uvr,pb,inv);
                    inv *= pb.z;
                    pa = vec3(0.,0.,-1.);
                    pb = vec3(0.,-0.5,2.);
                    pc = vec3(0.,0.5,2.);
                    uvr = roDot(uvr,inv);
                    break;
                }
                if(hitDot(uvr,pc)){
                    uvr = mapDot(uvr,pc,inv);
                    inv *= pc.z;
                    pa = vec3(0.,0.,-1.);
                    pb = vec3(0.,-0.5,2.);
                    pc = vec3(0.,0.5,2.);
                    uvr = roDot(uvr,inv);
                    break;
                }
                //OK, let's generate the new circles and go from there.
                pd = cdt(pa,pb,pc,false);
                pe = cdt(pa,pb,pc,true);
        
                //Only one of them is useful.  Figure out which one.
                pdm = max(pa.z,max(pb.z,pc.z));
                if(pd.z <= pdm){
                    pd = pe;
                }else if(pe.z - pd.z > 0.1){
                    pd = pe;
                }else if(length(uvr.xy-pe.xy) < length(uvr.xy-pd.xy)){
                    pd = pe;
                }
                //Did we hit our new circle?
                if(hitDot(uvr,pd)){
                    uvr = mapDot(uvr,pd,inv);
                    if(pa.z == 0.){
                        inv *= -pd.z;
                    }else{
                        inv *= -pd.z*sign(pa.z);
                    }
                    pa = vec3(0.,0.,-1.);
                    pb = vec3(0.,-0.5,2.);
                    pc = vec3(0.,0.5,2.);
                    uvr = roDot(uvr,inv);
                    break;
                }

                //We didn't hit a circle, let's figure out where we are.
                
                //We hit a gap! Yey!
                if(inTri(pb,pc,pd,uvr)){
                    pa = pd;
                    state = S_GAP;
                    break;
                }
                
                //We're on an edge.  Less yey.
                //Get the ray perpendicular to pd's
                //position on the circle,
                //oriented so that positive is toward pc
                vec2 bcr = pc.xy-pb.xy;
                bcr -= pd.xy*proj(pd.xy,bcr);
                //Which direction our point is in.
                //Can't be zero, or we'd have hit pd.
                dir = proj(uvr.xy-pd.xy,bcr);
                if(dir > 0.){ //keep pc
                    pb = pd;
                    break;
                }else{ //keep pb
                    pc = pd;
                    break;                
                }
            case S_EXT_CORNER: //We're in a corner, and it sucks.
                pa = vec3(0.); //There's an edge somewhere.
                pb = vec3(0.,0.,1.); //And a main circle.
                //Corner circle is weird.
                pc = vec3(vec2(2.*sqrt(2.)-2.)*sign(uvr.xy), 2.*sqrt(2.) + 3.);
                //Check for a hit...
                if(hitDot(uvr,pc)){
                    state = S_INT_ROOT;
                    uvr = mapDot(uvr,pc,inv);
                    inv *= -pc.z;
                    pa = vec3(0.,0.,-1.);
                    pb = vec3(0.,-0.5,2.);
                    pc = vec3(0.,0.5,2.);
                    uvr = roDot(uvr,inv);
                    break;
                }
                //We didn't hit it.  Are we in a smaller corner?
                if( sign(uvr.xy-pc.xy) == sign(uvr.xy) ){
                    //Yes. :(
                    uvr.xy = (uvr.xy-pc.xy)*pc.z;
                    inv *= pc.z;
                    break;
                }
                //We're on an outside edge.
                //That's a problem for the next iteration.
                state = S_EXT_EDGE;
                break;
            case S_EXT_EDGE: //Out on a flat edge.
                pa = vec3(0.); //Just in case.
                //Generate new circles...                
                pd = cdt(pa,pb,pc,false);
                pe = cdt(pa,pb,pc,true);
                //...and find the useful one
                pdm = max(pa.z,max(pb.z,pc.z));
                if(pd.z <= pdm){
                    pd = pe;
                }else if(pe.z - pd.z > 0.1){
                    pd = pe;
                }else if(length(uvr.xy-pe.xy) < length(uvr.xy-pd.xy)){
                    pd = pe;
                }
                
                /*/debug
                if(i > 2){
                glFragColor = vec4(sin(length(uvr.xy-pb.xy)*50.),sin(length(uvr.xy-pc.xy)*50.),sin(length(uvr.xy-pd.xy)*50.),0.);
                return;
                }
                //*/
                //Did we hit our new circle?
                if(hitDot(uvr,pd)){
                    state = S_INT_ROOT;
                    uvr = mapDot(uvr,pd,inv);
                    inv *= -pd.z;
                    pa = vec3(0.,0.,-1.);
                    pb = vec3(0.,-0.5,2.);
                    pc = vec3(0.,0.5,2.);
                    uvr = roDot(uvr,inv);
                    break;
                }
                //Check for gap.
                if(inTri(pb,pc,pd,uvr)){
                    pa = pd;
                    state = S_GAP;
                    break;
                }
                //No gap, check edge.
                //Since it's a flat edge, we can cheat.
                dir = 0.;
                if(abs(uvr.x) < abs(uvr.y)){
                    dir = (uvr.x-pd.x)*(pc.x-pb.x);
                }else{
                    dir = (uvr.y-pd.y)*(pc.y-pb.y);
                }
                if(dir > 0.){ //keep pc
                    pb = pd;
                    break;
                }else{ //keep pb
                    pc = pd;
                    break;                
                }
            case S_GAP: //Between three bounding circles.  Easy mode.
                //Generate new circles...                
                pd = cdt(pa,pb,pc,false);
                pe = cdt(pa,pb,pc,true);
                //...and find the useful one
                pdm = max(pa.z,max(pb.z,pc.z));
                if(pd.z <= pdm){
                    pd = pe;
                }else if(pe.z - pd.z > 0.1){
                    pd = pe;
                }else if(length(uvr.xy-pe.xy) < length(uvr.xy-pd.xy)){
                    pd = pe;
                }
                //Did we hit our new circle?
                if(hitDot(uvr,pd)){
                    state = S_INT_ROOT;
                    uvr = mapDot(uvr,pd,inv);
                    if(pa.z == 0.){
                        inv *= -pd.z;
                    }else{
                        inv *= -pd.z*sign(pa.z);
                    }
                    pa = vec3(0.,0.,-1.);
                    pb = vec3(0.,-0.5,2.);
                    pc = vec3(0.,0.5,2.);
                    uvr = roDot(uvr,inv);
                    break;
                }
                if(inTri(pb,pc,pd,uvr)){
                    pa = pd;
                    break;
                }
                if(inTri(pa,pc,pd,uvr)){
                    pb = pd;
                    break;
                }
                if(inTri(pa,pb,pd,uvr)){
                    pc = pd;
                    break;
                }
                //This is a thing that Should Not Happen.
                //So we're alerting on it.
                //glFragColor = vec4(1.);
                //return;
        } //end of switch, on to the next iteration.
        
        /*/
        if(i == PASSES-1){
            glFragColor = vec4(float(state%2),float((state/2)%2),float(state/4),0.);
            return;
        }
        //*/
        
    } //end of iteration, on to the actual rendering.
    
    //backoff = uvr;
        
    if(abs(inv)*SMALL > min(resolution.x,resolution.y)){
        uvr = backoff;
        inv = oinv;
    }
    
    inv = round(inv);
    
    
    /*

    float run = uvr.z/1.5;
    //float depth = ((log(abs(inv)+1.)/log(max(resolution.x,resolution.y))+1.)-1.)*1.5;
    float depth = (  log(abs(inv))  /  log(max(resolution.x,resolution.y))  );
    float edge = length(uvr.xy);
    float cycleTime = fract(time/SCALE);
    
    float breath = cos(cycleTime*TAU)/3.+2./3.;
    
    float starLev = fract(abs(inv)/7.)*7.;
    float starBreath = cos((cycleTime+starLev/7.)*TAU*6.)/2.+0.5;
    
    vec3 hi = mix(C_HI1,C_HI2,breath);
    //vec3 peak = mix(C_DOT,hi,(1.-edge)*(1.-edge));
    //vec3 twinkle = mix(peak,C_DOT,starBreath);
    
    vec3 dc = mix(C_DOT,hi,run);
    
    float pulse = starBreath/2.+0.5;
    
    //depth*smoothstep(1.0,0.9,edge)
    
    vec3 col = mix(C_BASE,dc,sqrt(depth)*smoothstep(pulse,pulse/2.,edge));
    */
    
    float cycleTime = fract(time/SCALE);
    
    
    vec3 base_col = vec3(-1.,1.,cos(inv+cycleTime*TAU));
    
    float rz = clamp(sqrt(uvr.z),0.1,0.9);

    vec3 col = (base_col*0.05+rz);
    
    
    
    
    
    //depth*smoothstep(1.0,0.9,edge)
    //vec3 col = vec3(,run,0.);
    //col = col * (1.-col)*4.;

    // Output to screen
    glFragColor = vec4(col,1.0);
}

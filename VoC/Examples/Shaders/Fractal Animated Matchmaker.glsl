#version 420

// original https://www.shadertoy.com/view/sdlBD4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159
#define TAU 6.28318
#define maxIterations 75
#define AA 2
#define time (time+12.5)/3.

//turn off julia mode: good for debugging 
//#define juliaFalse

vec2 cMult(vec2 c1, vec2 c2){
   //complex mult
    float newR = c1.x*c2.x - c1.y*c2.y;
    float newI = c1.y*c2.x + c1.x*c2.y;
    return vec2(newR,newI);
}

vec2 cDivide(vec2 c1, vec2 c2){
    //conjugate = a - bi;
    //to divide, multiply both sides by complex conjugate of denom

    float divisor = dot(c2,c2);
    
    return vec2((c1.x*c2.x + c1.y*c2.y)/divisor, (c1.y*c2.x - c1.x*c2.y)/divisor);
}

vec2 mobius(vec2 z, vec2 a, vec2 b, vec2 c, vec2 d){
    
    return cDivide(cMult(a,z)+b,cMult(c,z)+d);
}

vec2 f1(vec2 z, vec2 c) {
//return cMobius(cSquare(z), userSettings.posP, c, a, b);
    
    
    
    vec2 p = vec2(sin(time/4.),cos(time/4.))*mix(0.9,1.2,(cos(time/10.)));
    return mobius(cMult(z,z),p,c,vec2(0.3,0.6),vec2(-1.,0.));
}

vec3 palette(float loc, vec3 a, vec3 b, vec3 c, vec3 d) {
    return a + b*cos( TAU*(c*loc+d) );
}

float logPotential(float d,float i){
  
    float base=log(2.);
    return i-(log(log(d)/base)/base);

}

void main(void)
{
    
    vec3 aacol=vec3(0.);
    
        
    vec2 mPos = mouse*resolution.xy.xy/resolution.xx;
    mPos -= 0.5; mPos *= 1.3; mPos += 0.5;
    mPos=5.*(mPos-vec2(0.5,0.22));
    
    
    //aa code here
    for (int aax=0; aax<AA; aax++){
    for (int aay=0; aay<AA; aay++){
        vec2 c = vec2(0.);
        vec2 z = vec2(0.);
    
        vec2 uv = (gl_FragCoord.xy + vec2(aax,aay)/float(AA))/resolution.xx;
        uv -= 0.5;uv *= 1.3;uv += 0.5;
        uv=5.*(uv-vec2(0.5,0.22));
        z = uv;
        
        
        
        
        
        vec2 jPos = vec2(sin(-time/4.05),cos(-time/4.05))*1.1;
        
        
        //if (mouse*resolution.xy.z>0.)jPos=mPos;
        
                    
        int i = 0;
        float sum=0.; float fmin=10000.; float fmax=0.; float lenz=0.;
        
        //iterate
        #ifdef juliaFalse
            c=z;
        #else
            c=jPos;
        #endif
        for (i = 0; i < maxIterations; i++) {
            z = f1(z,c);
                        
            lenz = exp(0.-length(z));
            if (lenz<fmin) fmin=lenz;
            if (lenz>fmax) fmax=lenz;
            sum+=lenz;
        }

    
    //exp smoothing color method
    

    float colval = sqrt(sum)/(1.+fmax-fmin);
    
    
    vec3 iterationCol = vec3(palette(colval/2., vec3(0.5),vec3(0.5),vec3(1.0, 1.0, 0.0),vec3(0.3, 0.2, 0.2)));
    #ifdef juliaFalse
    if (distance(c,jPos)<0.03)iterationCol=vec3(0.);
    #endif
    
    aacol+= iterationCol;
    }
    }
    glFragColor=vec4(aacol.xyz/4.,1.);
}


#version 420

// original https://www.shadertoy.com/view/flXcRB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159
#define TAU 6.28318
#define maxIterations 100
#define AA 2

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
vec2 cPow(vec2 z, float p){
    if (p==1.) return z;
    float radius = sqrt(z.x*z.x + z.y*z.y);
    float theta = atan(z.y,z.x);
    float newR = pow(radius, p);
    return vec2(newR * cos(theta*p), newR * sin(theta*p));
}
vec2 cPow(vec2 c1, vec2 c2){
    return vec2(0);
}

vec2 f1(vec2 z, vec2 c) {
    return cPow(c,17.)+cMult(c,z);
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
    float time = time;
    
    //aa code here
    for (int aax=0; aax<AA; aax++){
    for (int aay=0; aay<AA; aay++){
        vec2 c = vec2(0.);
        vec2 z = vec2(0.);
    
        vec2 uv = (gl_FragCoord.xy + vec2(aax,aay)/float(AA))/resolution.xx;
        uv -= 0.5;uv *= 1.3;uv += 0.5;
    
        z.x = (uv.x - 0.5) ;
        z.y = (uv.y - 0.22) ;
        float zoom = 3.;
        z*=zoom;
        
        bool escaped = false;
            
        int i = 0;
        c = vec2(sin(time/20.),cos(time/20.))*(1.1+cos(time/27.)*0.1);
        
        float orbit = 100.;
        
        vec2 jPos = vec2(0);
        //if(mouse*resolution.xy.z>0.){
        //    vec2 mPos = mouse*resolution.xy.xy/resolution.xx;
        //    mPos -= 0.5; mPos *= 1.3; mPos += 0.5;
        //    mPos=zoom*(mPos-vec2(0.5,0.22));
        //    c=mPos;
        //}
    
        float brightness = 0.;
        float totalBs = 0.;
        float avgI = 0.;
        float biggestI = 0.;
        float maxB = 0.;
        
        //iterate
        for (i = 0; i < maxIterations; i++) {
          orbit = min(length(z), orbit);
          z = f1(c,z);
          
          //calculate orbit trap values:
          float newDist = min(abs(z.x),abs(z.y));
          if (newDist < 1.){
            float b = max(0., 0.-log(newDist + 0.0001)*0.05);
            avgI += float(i) * b; //this is a weighted average function that will help decide what color to use.
            totalBs += b; //still for the weighted average function
            if (b > brightness) biggestI = float(i);
            brightness = 1. - (1. - brightness) * (1. - b); //screen function
            maxB = max(maxB, b);
          }
            

        }
        avgI = avgI*2. / totalBs;

    float fractionOfOrbit = avgI / float(maxIterations);
    brightness = (brightness + maxB)/2.;
    
    
    vec3 iterationCol = vec3(palette(fractionOfOrbit, vec3(0.5),vec3(0.5),vec3(1.0, 1.0, 0.0),vec3(0.3, 0.2, 0.2)));

    aacol+= vec3(iterationCol * brightness*3.);
        
    }
    }
    glFragColor=vec4(aacol.xyz/4.,1.);
}


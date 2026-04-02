#version 420

// original https://www.shadertoy.com/view/NdXBzr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159
#define TAU 6.28318
#define maxIterations 128
#define AA 2

vec2 cMult(vec2 c1, vec2 c2){
   //complex mult
    float newR = c1.x*c2.x - c1.y*c2.y;
    float newI = c1.y*c2.x + c1.x*c2.y;
    return vec2(newR,newI);
}

vec2 f1(vec2 z, vec2 c) {
    return mat2(z,-z.y,z.x)*z + c;///mandelbrot
}

float sdSegment( in vec2 p, in vec2 a, in vec2 b )//from iq
{
    vec2 pa = p-a, ba = b-a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return length( pa - ba*h );
}

float fTrap(vec2 z){
    
    vec2 center= vec2(sin(time)*(2.*sin(time/5.)+4.2), cos(time)*(2.5*sin(time/6.)+5.6)) - z;
    float offset = 0.4*(sin(time/3.)+1.)+0.2;
    return sdSegment(z,center+offset,center-offset);
}
vec3 palette(float loc, vec3 a, vec3 b, vec3 c, vec3 d) {
    return a + b*cos( TAU*(c*loc+d) );
}

void main(void)
{
    
    vec3 aacol=vec3(0.);
    float time = time;
    
    //aa code here
    for (int aax=0; aax<AA; aax++){
    for (int aay=0; aay<AA; aay++){
    
        
        
        vec2 uv = (gl_FragCoord.xy + vec2(aax,aay)/float(AA))/resolution.xx;
        uv -= 0.5;uv *= 1.3;uv += 0.5;
        vec2 c=vec2(0);
        c*=2.5;
        c.x =(uv.x - 0.5) ;
        c.y =(uv.y - 0.22);
        
        vec2 offset = vec2(1,0.1)*sin(time/7.)+vec2(-0.1,0.1)*cos(time/7.);
        c+=offset;
        
        
        vec2 z = c;//
         c=vec2(-0.8,0.156);//−0.8 + 0.156i
    
        
        float closest = 4.;
        float closest2 = 4.;
        int smallestI = 0;
        
        //vec2 dir = vec2(0);
        //iterate
        for (int i = 0; i < maxIterations; i++) {
              z = f1(z,c);
              
              //vec2 p = fTrap(z);
              //float dist = length(p);
              float dist = fTrap(z);
              if (dist < closest){
                closest2 = closest;
                closest = dist;
                smallestI = i;
                //dir=normalize(p);
            }else if (dist < closest2){
                closest2 = dist;
                
            }
        }
        vec3 col = vec3(palette(float(smallestI)/20., vec3(0.5),vec3(0.5),vec3(1.0, 1.0, 0.0),vec3(0.3, 0.2, 0.2)));

        float shadow = sqrt(clamp(sqrt(clamp(1.-closest/closest2,0.,1.))*1.5,0.,1.));
        float highlight = clamp(4.* (0.2-(closest/closest2)),0.,1.);

        col=col*shadow+highlight;
        
        /*
        dir*=closest/closest2;
        vec3 normal = vec3(dir.xy, sqrt(1. - dot(dir,dir)));
    
        col *= texture(iChannel0, (normal)).rgb*1.75;
        */
        col=col*(-1./float(maxIterations)*float(smallestI)+1.);
        
        aacol+=col;
    }
    }
    glFragColor=vec4(aacol.xyz/4.,1.);
}


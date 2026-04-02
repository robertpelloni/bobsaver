#version 420

// original https://www.shadertoy.com/view/ttsXDB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//Based on the original formula from http://paulbourke.net/fractals/magnet/
//Modified with different constants which change based on time and iteration

//Thanks to FabriceNeyret2 for some additional optimizations!
//Golfed version with 292 chars:
/*
#define S x-=1.+.5*sin((time+i)//
#define M mat2( z, -z.y, z )//
void main(void) //WARNING - variables #define (O,U)                                  \ need changing to glFragColor and gl_FragCoord
    float N=128., i=0., m=4., l=N;                      \
    for( vec2 n = resolution.xy, z = n-n,              \
              u = 2.* ( U+U-n )/n.y;                    \
        i<N && l>0.;                                    \
         l =  4.-length(z=M*z) )                        \
         l < m ? m = l : m,                             \
         n = z+z + u,                                   \
         z = M*z + u,                                   \
         z.S/2.6),                             \
         z = M * vec2( n.S/2.)+.5, -n.y ) / dot(n,n),\
         O = m * ( cos(vec4(1,2,3,0)-5.*i++/N) + 1. ) / 8.
*/

float MAX_STEPS=128.;
float PI=acos(-1.);
float AA=2.;

#define vecMul(a,b) vec2(a.x*b.x-a.y*b.y,a.x*b.y+a.y*b.x)
#define vecDiv(a,b) vec2(a.x*b.x+a.y*b.y,a.y*b.x-a.x*b.y)/(b.x*b.x+b.y*b.y)

mat2 matRot(float a){
    float c=cos(a),
          s=sin(a);
    return mat2(c,s,s,-c);
}

vec3 samplePoint(vec2 c){
    float i;
    vec2 z=vec2(0.);
    float maxl=0.;
    for(i=0.;i<MAX_STEPS;i++){
        vec2 numer = vecMul(z,z)+c; numer.x-=1.+.5*sin((time+i)/2.6);
        vec2 denom = 2.*z+c;        denom.x-=1.5+.5*sin((time+i)/2.);
        vec2 div   = vecDiv(numer,denom);
        z = vecMul(div,div);
        float d=dot(z,z);
        if(d>16.){
            break;
        }
        maxl=max(maxl,d);
    }
    
    float ic=(5.*i/MAX_STEPS);
    return (4.-sqrt(maxl))*(cos(vec3(1,2,3)-ic)+1.)/8.;
}

void main(void) {
    vec2 c=2.*(2.*gl_FragCoord.xy-resolution.xy)/resolution.y;
    float delt=(2./resolution.y)/AA;
    vec3 col;
    for(float y=0.;y<AA;y++){
        for(float x=0.;x<AA;x++){
            col+=samplePoint(c+vec2(x,y)*delt);
        }
    }
    col/=(AA*AA);
    glFragColor = vec4(col,1.0);
}

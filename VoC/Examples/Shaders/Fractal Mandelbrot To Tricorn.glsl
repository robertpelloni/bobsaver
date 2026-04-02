#version 420

// original https://www.shadertoy.com/view/4sKSz1

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// The formula of the complex mandelbrot set is z=sqr(z)+c
// The formula of the complex tricorn set is z=sqr(conj(z))+c
// I used quaternion rotation in the hypercomplex plane to make a smooth transition between these two set.

const int n = 64;

vec4 qmult(vec4 a,vec4 b)
{
    return vec4(a.x*b.x-a.y*b.y-a.z*b.z-a.w*b.w,
                a.x*b.y+a.y*b.x+a.z*b.w-a.w*b.z,
                a.x*b.z+a.z*b.x+a.w*b.y-a.y*b.w,
                a.x*b.w+a.w*b.x+a.y*b.z-a.z*b.y);
}

float time2;

void main(void)
{
    time2 = time*.2;
    vec2 uv = gl_FragCoord.xy / resolution.y;
    vec4 um = vec4(1.0);
    vec4 quv= 3.*vec4(uv-vec2(.5+(resolution.x-resolution.y)/(2.*resolution.y),.5),0,0);
    vec4 qum= 3.*vec4(um.xy-vec2(.5+(resolution.x-resolution.y)/(2.*resolution.y),.5),0,0);
    vec4 s = normalize(vec4(0,0,1,1)); //the value of the vector should be (0,0,a,b) with (a,b)!=(0,0)
    vec4 q = vec4(cos(time2),0,0,0)+sin(time2)*s;
    vec4 qi = (vec4(cos(time2),0,0,0)+sin(time2)*s)*vec4(1,-1,-1,-1);
    vec4 c = quv;// use qum istead of quv to make julia sets (not really interresting)
    vec4 z = quv;
    float f =0.;
    for(int i=0;i<n;i++){
        z = qmult(q,qmult(qmult(z,z),qi))+c; //"rotate" z at each iteration
        f++;     
        if(length(z)>2.)return;
          }
    
    
    glFragColor = vec4(f/float(n));
}

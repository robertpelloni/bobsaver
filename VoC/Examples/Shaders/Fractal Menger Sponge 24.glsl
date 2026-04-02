#version 420

// original https://www.shadertoy.com/view/7dlfzS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/**
Gaz smol raymarch + meger sponge fracal from previous week shader (lost ref T_T))

*/

#define R(p,a,t) (mix(a*dot(p,a),p,cos(t))+sin(t)*cross(p,a))
mat2 rot(float a){float c=cos(a),s=sin(a);return mat2(c,-s,s,c);}
// distance to a menger sponge of n = 1
float crossDist( in vec3 p ) {
  
    vec3 absp = abs(p);
  
    //return length(p.yx+sin(p.z)*.05)-2.7;
    // get the distance to the closest axis
    float maxyz = max(absp.y, absp.z);
    float maxxz = max(absp.x, absp.z);
    float maxxy = max(absp.x, absp.y);
    float cr = 1.0 - (step(maxyz, absp.x)*maxyz+step(maxxz, absp.y)*maxxz+step(maxxy, absp.z)*maxxy);
    // cube
    float cu = max(maxxy, absp.y) - 3.0;
    // remove the cross from the cube
    return max(cr, cu);
}

// menger sponge fractal
float fractal( in vec3 p ) {
    vec3 pp = p;
    float scale = 1.0;
    float dist = 0.0;
    for (int i = 0 ; i < 6 ; i++) {
    
        dist = max(dist, crossDist(p)*scale);
        
        p = fract((p-1.0)*0.5) * 6.0 - 3.0;
        scale /= 3.;
        //p.yz*=rot(.785);
        
    }

    return dist;
}
vec3 pal(float t){ return vec3(.4,.5,.6)+vec3(.2,.3,.5)*cos(6.28*(vec3(.2,.2,.3)*t+vec3(.2,.5,.8)));}
void main(void)
{
    vec3 p,c=vec3(0.);
    vec3 d = normalize(vec3(gl_FragCoord.xy -.5*resolution.xy,resolution.y));
    for(float i=0.,s,e,g=0.,t=time;i++<50.;){
        p=g*d;
        p = R(p,normalize(vec3(.1+cos(time*.5+p.z*.2)*.5,sin(time*.5+p.z*.2)*.5,.5)),.5+t*.2);

        p.z +=time;
        p=asin(cos(p))-vec3(2,4,1);
        p = mod(p,4.)-2.;
        s=1.;
        
        g+=e=max(.0001,abs(fractal(p))+.0009);
        c+=2.*sqrt(pal(p.z/6.28))*.02/exp(i*i*e);
    }
    c*=c;
    glFragColor = vec4(c,1.0);
}

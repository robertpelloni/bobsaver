#version 420

// original https://www.shadertoy.com/view/ttfcRB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//fast and ez
vec3 color(float x){
    x=sin(x);//so it loops nicely
    //x=abs(sin(x));//limits colors 
    //bezier, you can rearange the functions for different color combos but this one is best
    float r=(1.0-x)*(1.0-x);
    float g=x*x;
    float b=2.0*(1.0-x)*x;
    return vec3(r,g,b);
}

float orbitMeasure(vec2 point){
    //point 
    //return distance(point,vec2(-1,0));
    
    //shifted line 
    //vec2 s=vec2(-2,0);//offset
    //vec2 dir=vec2(cos(time),sin(time));//direction of line
    //float d=dot(point-s,dir)/length(dir);
    //return sqrt(length(point-s)*length(point-s)-d*d);
    
    //shifted circle
    //note the point is just a 0 radius circle 
    vec2 c=2.1*vec2(cos(time)-.25,sin(time));// this looks cool
    //vec2 c=vec2(1,0);
    float r=1.4;
    return abs(r-length(point-c));
    
    //any function that takes in a 2d vector and outputs a scalar, preferably positive scalars 
}

//(x+yi)^2=(x+yi)(x+yi)=x^2+(yi)^2+2xyi since i^2=-1 then =x^2-y^2+2xyi 
vec2 square(vec2 n){
    return vec2(n.x*n.x-n.y*n.y,2.0*n.x*n.y);
}

//const vec2 center=vec2( -0.743643887037158704752191506114774, 0.131825904205311970493132056385139);
const vec2 center= vec2(-1,0);
const int maxiter=100;

void main(void)
{
    vec2 uv=1.5*((2.*gl_FragCoord.xy-resolution.xy)/resolution.y);
    //uv/=exp2(time);
    uv+=center;
    
    float mini=1e20f;
    vec2 value=vec2(0);
    for(int i=0;i<maxiter;i++){
        value=square(value)+uv;
        mini=min(orbitMeasure(value),mini);   
    }
       glFragColor=vec4(color(length(mini+2.5)*2.5)*.8,1);
}

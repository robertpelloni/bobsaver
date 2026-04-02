#version 420

// original https://www.shadertoy.com/view/ls2cWt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Created by David Crooks
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

#define TWO_PI 6.283185
#define PI 3.14159265359

struct Circle {
    float radius;
    vec2 center;
};

const int numCircles = 3;
Circle circles[3];

/*
    Orthoganl Circles represent strait line in hyperbolic space.
    
    see http://mathworld.wolfram.com/PoincareHyperbolicDisk.html.

*/
Circle orthogonalCircle(float theta1,float theta2) {
    
    float theta = 0.5*(theta1 + theta2);
    float dTheta = 0.5*(theta1 - theta2);
    
    float r = abs(tan(dTheta));
   //  float r = 0.5;
    float R = 1.0/cos(dTheta);
    
    vec2 center = vec2(R*cos(theta),R*sin(theta));
    
    return Circle(r,center);
}

void createCircles() {

    float t = 0.5 - 0.5*cos(time);

      float theta = TWO_PI/3.0;
   
    
    float dTheta = 2.43 + 0.152*t;
    
    //for(int i;i<numCircles  )
    circles[0] = orthogonalCircle(0.0,dTheta);
    circles[1] = orthogonalCircle(theta,theta + dTheta);
    circles[2] = orthogonalCircle(2.0*theta,2.0*theta +  dTheta);
}

bool circleContains(vec2 p, Circle c) {
    
   return distance(c.center,p) < c.radius;
    
}

/*
    Circle inversion exchanges the inside with the outside of a circle.
    Reflections in hyperbolic space.
*/
vec2 circleInverse(vec2 p, Circle c){
    
    return ((p - c.center) * c.radius * c.radius)/(length(p - c.center) * length(p - c.center) ) + c.center;
    
}

bool isEven(int i){
    
    return mod(float(i),2.0) == 0.0;
    
}

/*
    Iterated Inversion System 
    see this paper http://archive.bridgesmathart.org/2016/bridges2016-367.pdf
    and this shader https://www.shadertoy.com/view/XsVXzW by soma_arc.

    This algorythim for draws tileings on the poncaire disk model of hyperbolic space.
    
    Our array of circles represent the reflections that generate the tiling.
    We repeatedly invert the point in each of the circles and keep track of the total number of inversions.

*/

bool iteratedInversion(vec2 p) {
    

    int count = 0;
    bool flag = true;
    
    for(int i=0; i<100; i++) {
        
        flag = true;
        
        
        for(int j = 0; j<numCircles; j++) {
            Circle c = circles[j];

            if(circleContains(p, c)) {
                
                p = circleInverse(p,c);
                flag = false;
                count++;  
                
            } 
            
        }
        
        if(flag) {
           break;
        }
        
    }
    
    return isEven(count);
    
}

float drawCircles(vec2 p) {
    
    float  d0 =  abs(distance(circles[0].center,p) - circles[0].radius);
    float  d1 = abs(distance(circles[1].center,p) - circles[1].radius);
    float  d2 =  abs(distance(circles[2].center,p) - circles[2].radius);
    
    float disk = abs(length(p) - 1.0);
   
    float d =  min(min(min(d0,d1),d2),disk);
    
    if(d<0.01) {
         return 0.0;   
    }
    else {
        return 1.0 - 0.5*d;  
    }
}

void main(void)
{
    createCircles();
    
    vec2 uv = 2.0*(gl_FragCoord.xy - 0.5*resolution.xy) / resolution.y;
    
    float r = length(uv);
    
    vec4 black = vec4(vec3(0.0),1.0);
    vec4 white = vec4(1.0);
    
    
    //Uncomment this to see the circles that generate the tiling
    //glFragColor = vec4(vec3(drawCircles( uv)),1.0); return;
   
   
    if (r<1.0){
        if (iteratedInversion(uv)) {

            glFragColor = white;

        }
        else {

            glFragColor = black;

        }   
    }
    else {
        glFragColor = black;
    }
}

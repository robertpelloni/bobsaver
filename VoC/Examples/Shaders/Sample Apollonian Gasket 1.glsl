#version 420

// original https://www.shadertoy.com/view/ltySR1

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 Scale(vec2 p){
    float MinRes = min(resolution.y,resolution.x);
    return (p.xy*2.-resolution.xy)/MinRes*2.;
}

vec2 complexMultiply(vec2 a, vec2 b){
    return vec2(a.x*b.x-a.y*b.y,a.x*b.y+a.y*b.x);
}

vec2 complexSqrt(vec2 z){
    float r = sqrt(length(z));
    float a = atan(z.y,z.x)*.5;
    return r*vec2(cos(a),sin(a));
}

mat2 getRotationMatrix(float a){
    return mat2(cos(a),sin(a),-sin(a),cos(a));
}

void main(void) {
    float MinRes = min(resolution.y,resolution.x);
    
    mat2  r = getRotationMatrix(time*.3);
    
    float  LineEpsilon =  1./MinRes;
    
    vec2 z = Scale(gl_FragCoord.xy);
    
    //midpoint circles
    vec2 m1 = Scale(mouse*resolution.xy);
    vec2 m2 = vec2(-.5, .5);
    vec2 m3 = vec2(-.5,-.5);
    
    //distance from i to next
    float d1 = distance(m1,m2);
    float d2 = distance(m2,m3);
    float d3 = distance(m3,m1);
    
    //radius circles
    float r1 = ( d1-d2+d3)*.5;
    float r2 = ( d1+d2-d3)*.5;//d1-r1
    float r3 = (-d1+d2+d3)*.5;//d3-r1
    
    //curvature circles
    float k1 = 1./r1;
    float k2 = 1./r2;
    float k3 = 1./r3;
    
    //curvature descarte circle
    float k4 = k1+k2+k3-2.*sqrt(k1*k2+k2*k3+k3*k1);
    
    //radius descartes circles 
    float r4 = abs(1./k4);

    //descarte circle midpoint, surprisingly difficult...
    vec2 m4 = (m1*k1 
             + m2*k2 
             + m3*k3 
             + 2.*complexSqrt(
                 complexMultiply(m1,m2)*k1*k2 
               + complexMultiply(m2,m3)*k2*k3 
               + complexMultiply(m1,m3)*k1*k3 
             ))/k4;
    
    
    //fractal loop, basic scaling
    //s keeps track of total scaling
    float its = 0.;
    float s = 1.;
    for(int i=0;i<4;i++){
        
        if(distance(z,m1)<r1){
             z = (z-m1)/r1;
             s =      s/r1;
            
        }else if(distance(z,m2)<r2){
             z = (z-m2)/r2; 
             s =      s/r2;
            
        }else if(distance(z,m3)<r3){
             z = (z-m3)/r3;  
             s =      s/r3;
            
        }else{
            
            break;
            
        }
        
                
        z *= r;
           
        z = m4 + z*r4;
        s =    + s*r4;
      
        its++;
    }

    //get distance to the four circle edges
    float dis = 1e20;
    dis = min(dis,abs(distance(z,m1)-r1));
    dis = min(dis,abs(distance(z,m2)-r2));
    dis = min(dis,abs(distance(z,m3)-r3));
    dis = min(dis,abs(distance(z,m4)-r4));
    
    dis /= s;//scale distance back to actual distance
   
    float smoothed = smoothstep(1./LineEpsilon,0.,1./dis)/(its*.1+1.);
    

    glFragColor = vec4(smoothed);
}

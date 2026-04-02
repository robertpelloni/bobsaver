#version 420

// original https://www.shadertoy.com/view/7sjBDm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//Twitter: @smjtyazdi

#define PI 3.14159265
#define N 8.0
const float scale = 0.25;

float ps(vec2 pos,float  time){                //Calculates the angle of emission of the corresponidng field curve that passes trough this point
    float t = atan(pos.y,pos.x)+ atan(pos.y,1.-pos.x);
    return t + time;
}

vec2 e(vec2 pos){                              //Calculates electric field
    vec2 b = pos - vec2(1.,0.);
    vec2 res = pos/dot(pos,pos) - b/dot(b,b);
    return res;
}

float v(vec2 pos){                            //Calculates electric potential
    vec2 b = pos - vec2(1.,0.);
    float res = log(length(pos)/length(b));
    return res;
}

float dis_radian(float t1,float t2){         //Shortest distance between two angles t1 and t2
    if(abs(t1-t2)<PI)return abs(t1-t2);
    else return 2.*PI-abs(t1-t2);
}

vec3 Palette(float t){                       //Color Palette
    return mix(vec3(1.,0.05,0.05),vec3(0.05,0.05,1.),t);
}

vec3 render(vec2 p,float time){

    p.x += 0.5;                             //Center
    
    float v = v(p);                         //Potential of the point
    
    float alpha = 1.5;                      //Amount of latency
    
    float dv = (1.-exp(v)/(exp(v)+1.));     //Calculate latency from potential
    
    time += dv*alpha;                       //Add latency
    
    time = (0.5-0.5*cos(time*PI/1.))*2.0;      //Rotating effect
    
    float theta = ps(p,time);               //Angle of emission of the field curve that passes trough this point
    vec2 ee = normalize(e(p));              //Electric field direction
    ee = vec2(ee.y,-ee.x);                  //Electric field direction rotated 90 degrees
    float theta2 = ps(p + ee*0.02 , time);  //Angle of emission for a neighbor point 
    float thickness = dis_radian(theta2,theta)*0.3;
                                            //calculate thickness base on the angle of emmisions of the two neighboring points
    
    theta = theta - round(theta/PI*N)*PI/N;
    
    if(abs(theta)<thickness)return Palette(dv)*exp(-pow(abs(theta)/thickness,2.));
    
    return vec3(0.);
}

void main(void)
{
   
   vec2 p = (gl_FragCoord.xy - resolution.xy/2.0)/(scale*resolution.y);

   float time = time/2.;
    
   vec3 col = vec3(0.);
   
   for(float k=0.;k<20.;k+=1.){
       vec3 res = render(p,time-k/400.);
       col += res/(2. + k)*3.;
   }
   
   glFragColor = vec4(col,1.0);
}

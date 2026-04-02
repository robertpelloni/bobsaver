#version 420

// original https://www.shadertoy.com/view/WsGGDd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159
#define t time*PI/4.
 
vec2 cartesian2polar(vec2 cartesian){
    return vec2(atan(cartesian.x,cartesian.y),length(cartesian.xy));
}

vec2 polar2cartesian(vec2 polar){
    return polar.y*vec2(cos(polar.x),sin(polar.x));
}

vec2 rotate2D(vec2 coords, float amount){
    return polar2cartesian(cartesian2polar(coords)+vec2(amount,0.));
}

void main(void)
{ 
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    uv = rotate2D(uv, t);
 
    vec3 col = vec3(.3);
    
    int iterationID = 0; 
    float iterations =  max(2. + (-4.*cos(t/2.)-PI/2.),0.);        //how many layers, you can manually just enter 5.0 or 20.0 and see what happens
       float circleRadius = .25;
    
    for(int i = 0; i< int(iterations); i++){               //loop for KIFS fractal, keep transforming the uvs inside the inner circles into the uv of the whole circle
     float distToInner = length(abs(uv)-vec2(0,circleRadius));
        if(distToInner<circleRadius){            //inner circle
           uv.y = (uv.y>=0.)?(uv.y-circleRadius):(uv.y+circleRadius);
        uv*=2.;
        iterationID++;
        uv = rotate2D(uv,-PI/2. + t * float(iterationID)  );
           }
       
    }
     
     float distToInner = length(abs(uv)-vec2(0,circleRadius));
        if(distToInner<circleRadius*fract(iterations) ){            //inner circle
           uv.y = (uv.y>=0.)?(uv.y-circleRadius):(uv.y+circleRadius);
        uv*=2.;
        iterationID++;
        uv = rotate2D(uv,-PI/2. +  t * float(iterationID)  );
           }
    
    if(length(uv)<.5){
    col = vec3(step(0.,uv.x));
        
        float distToInner = length(abs(uv)-vec2(0,.25));
        if(distToInner<circleRadius){            //inner circle
            col = vec3(step(0.,uv.y) ); 
           
            if(distToInner>circleRadius/2.){     //final most inner circle/iris
                 col = vec3( -col.x +1.); 
            }
        } 
    }
    glFragColor = vec4(col,1.0);
}

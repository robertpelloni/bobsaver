#version 420

//An attempt at hex life rule described here http://www.well.com/~dgb/hexrules.html
//Reset by moving your mouse to the left side of the screen,
//randomize by moving it to the right side

// This pattern have at least one walker (It is quite large so play around a bit to find it), and two larger oscillators. 
// > I agree, this pattern is a cooler. I have moved the rule constants so they are easier to modify. 
// > mod: I like these numbers better. They don't die as fast and more complex behavior emerges. No gliders yet though

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;
uniform sampler2D backbuffer;

out vec4 glFragColor;

//Hex radius. 
const float hexR = 2.;

//Experiment with these:

//Weight of a primary neighbor (adjacent hex).
const float primaryNodeW   = 1.;
//Weight of a secondary neighbor (tip of "star of David")
const float secondaryNodeW = 0.33;

//Upper and lower limits for keep alive and birth rules.
const float lKeepAlive = 1.9; 
const float uKeepAlive = 3.3;
const float lBirth     = 2.1;
const float hBirth     = 3.2;
    
//---------------------------------------------------

#define PI 3.14159265359
#define TAU 6.28318530718
#define deg60 1.0471975512
#define deg30 0.52359877559

// from https://glsl.heroku.com/e#15131.0
vec2 nearestHex(float s, vec2 st){
    float h = sin(deg30)*s;
    float r = cos(deg30)*s;
    float b = s + 2.0*h;
    float a = 2.0*r;
    float m = h/r;

    vec2 sect = st/vec2(2.0*r, h+s);
    vec2 sectPxl = mod(st, vec2(2.0*r, h+s));
    
    float aSection = mod(floor(sect.y), 2.0);
    
    vec2 coord = floor(sect);
    if(aSection > 0.0){
        if(sectPxl.y < (h-sectPxl.x*m)){
            coord -= 1.0;
        }
        else if(sectPxl.y < (-h + sectPxl.x*m)){
            coord.y -= 1.0;
        }
    }
    else{
        if(sectPxl.x > r){
            if(sectPxl.y < (2.0*h - sectPxl.x * m)){
                coord.y -= 1.0;
            }
        }
        else{
            if(sectPxl.y < (sectPxl.x*m)){
                coord.y -= 1.0;
            }
            else{
                coord.x -= 1.0;
            }
        }
    }
    
    float xoff = mod(coord.y, 2.0)*r;
    return vec2(coord.x*2.0*r-xoff, coord.y*(h+s))+vec2(r*2.0, s);
}

float maxNorm(vec3 x){
    return max(x.x,max(x.y,x.z));    
}

vec2 neighborHex(vec2 x, float d, int i){
    return x-2.*d*vec2(cos(float(i)*deg60),sin(float(i)*deg60));
}

float rand(vec2 co){
  return fract(cos(dot(co.xy ,vec2(0.94393,3.394394))) * 43758.5453);
}

void main( void ) {

    if(mouse.x<0.01){
        glFragColor =    vec4(vec3(0.0),1.0);
        return;
    }
    
    vec3 col = vec3(0.0);
        //vec2 hexCoord = ( gl_FragCoord.xy);
    
    vec2 hexCoord = nearestHex(hexR, gl_FragCoord.xy);
    
    if(mouse.x>0.99){
        glFragColor =    vec4(vec3(rand(hexCoord*floor(time))>0.5),1.0);
        return;
    }
    
    float p = 0.;

    
    for(int i = 0; i<6; i++){
        vec2 n1 = neighborHex(hexCoord,hexR,i); //Primary neighbor
        vec3 nc1 = texture2D(backbuffer,n1/resolution.xy).xyz;
        
        if(maxNorm(nc1)>0.01)
            p+=primaryNodeW; //Primary neighbor weight
        
        vec2 n2 = neighborHex(n1,hexR,i+1); //Secondary neighbor
        vec3 nc2 = texture2D(backbuffer,n2/resolution.xy).xyz;
        if(maxNorm(nc2)>0.01)
            p+=secondaryNodeW; //secondary neighbor weight
        
        
        col += primaryNodeW*nc1+secondaryNodeW*nc2;
        
    }
    
    vec3 selfcol = texture2D(backbuffer,hexCoord/resolution.xy).xyz;
    //Propagation Rule
    if(maxNorm(selfcol)>0.01){
        if((lKeepAlive <= p) && (p <=uKeepAlive))
            col = mix(selfcol,col,0.5);
        else
            col = vec3(0.0);
    }else{
        if((lBirth <= p) && (p <= hBirth))
            col = col;
        else
            col = vec3(0.0);
    }
    
        vec2 position = hexCoord/resolution.xy;    
    if(distance(resolution.xy*mouse,hexCoord)<=25.){
        col = vec3(0.5+0.5*sin(0.01*hexCoord.x+0.2*time),0.5+0.5*sin(0.01*hexCoord.y+0.3*time),0.5);
    }
    col /= maxNorm(col);
    glFragColor = vec4(col, 1.0);
}

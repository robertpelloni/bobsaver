#version 420

// original https://www.shadertoy.com/view/MdyyRy

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define M_PI 3.1415926535897932384626433832795
vec3 circle(vec2 uv,float r,vec2 pos,float rBlur,float value){
    vec3 col;
    float l = length(uv-pos);
    col= vec3(smoothstep(r,r-rBlur,l))*((0.2+value)); 
    return col;    
}

vec2 normalizeCoords(vec2 coords,float prop){
    vec2 vecOut;
    vecOut = ((coords/resolution.xy)-0.5);
    vecOut.x*=prop;
    return vecOut;
}         

void main(void) {
    float prop = resolution.x/resolution.y;
    vec2 uv = normalizeCoords(gl_FragCoord.xy,prop);
    //vec2 mousePos=normalizeCoords(mouse*resolution.xy.xy,prop); idea for a fun mouse input ?
    vec3 col;
    float rSpeed=0.5;
    float d =0.3 +0.06*sin(time*rSpeed);
    float speed = 3.;
    
    vec3 background= circle (uv,d*1.5,vec2(0.),d*5.,1.);
    background.xyz+=vec3(0.05,0.,0.15);
     
    
 
    
    background*=circle (uv,1.5,vec2(0.),1.4,1.);;
    
    vec3 planet = 1.-circle(uv, d*0.7,vec2 (0),0.02,1.);
    
    for (float i=1.;i<25.;i++){
        
        float offset=.2;
         float st = speed*time;
        
        // co is similar to the cos that define x coordinate
        // but with some offset and remap to use as a radius factor
        float co=(cos(st+offset*i*1.5+M_PI*.5)+1.)/2.;
        
        float x=d*cos(st+offset*i*1.5);
        float y=d*sin(st*0.6+offset*i*0.9);
        
        vec2 pos=vec2 (x,y);
        
        float r;
        
      
       
        r=0.02*co*co+0.0045*i; 
        
        float a=1.-0.09*(20.-i);

        vec3 colCircle=circle(uv, r,pos,0.03,co);
        vec3 colCircle2=circle(uv, r,pos,0.3,co);
        
        colCircle.x/=(2.*a);
        colCircle.y*=0.5;
        
        vec3 colCircleTot=(colCircle+colCircle2*a)*a;
        
        if(co<0.5)colCircleTot*=planet;
        
        
        col=max (col,colCircleTot);

        
    }
       col+=background*planet;  
    
    // Output to screen
    glFragColor = vec4(col,1);
    
}


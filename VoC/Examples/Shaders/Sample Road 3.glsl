#version 420

// original https://www.shadertoy.com/view/4dfBWH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    
    vec2 turn = uv;
    
    turn.x+=cos(time*1.5+uv.y*4.0)*0.15+cos(time+uv.y*4.0)*0.15;
    float turntime=cos(time*1.5+2.0)*0.15+cos(time+2.0)*0.15;
    
    float ground=abs((turn.x-0.5)/(-turn.y*1.15+0.6));
    ground=round(pow(3.0*ground,2.0));
    
    vec3 groundcolor;
    
    if(uv.y<0.5){
        if(ground==0.0){
            groundcolor=vec3(0.3,0.3,0.3);
     
        }
        if(ground==1.0){
            groundcolor=vec3(0.2,0.2,0.2);
     
        }
        if(ground==2.0){
            groundcolor=vec3(1.0,0.6,0.2);
     
        }
        if(ground==3.0){
            groundcolor=vec3(0.0,0.6,0.2);
     
        }
        if(ground>=4.0){
            groundcolor=vec3(0.0,0.4,0.2);
     
        }
        
        groundcolor*=clamp(round((sin(pow(uv.y*6.0,3.0)+time*4.0)+1.0)*0.5)+0.8,0.0,1.0);

    }else{
        
        float mountain=round((cos((uv.x+turntime+0.7)*7.0)+cos((uv.x+turntime)*11.0)+cos((uv.x+turntime)*13.0)+2.0)-(uv.y*3.0));
        groundcolor=vec3(0.0,mountain*0.3,mountain*0.15); 
        
        if(groundcolor.y<=0.0){
         groundcolor=vec3(0.0,0.6,1);   
        }
        
      //  if(groundcolor.y==0.3){
           // float nieve=round((uv.y*4.0))/4.0;
          //  groundcolor=vec3(nieve,1.0,nieve);   
            
        //}
        
    }
    
    
    
    
    glFragColor = vec4(groundcolor,1.0);
}

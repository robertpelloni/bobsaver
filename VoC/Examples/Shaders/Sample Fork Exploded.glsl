#version 420

// original https://www.shadertoy.com/view/lfjBRG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//learn from : https://www.shadertoy.com/view/dtf3Ws
void main(void)
{
     // thank for jolle's comment,the extended glow cause great waste!
     //but it doesn't look so natural on the edge
     vec2 d = (gl_FragCoord.xy-resolution.xy*0.5)/resolution.y*0.5;
     if (dot(d, d) > 0.55)
     {
     glFragColor = vec4(0.);
     return;
     }
        
     //Clear base color.
    glFragColor-=glFragColor;
    
    vec2 r = resolution.xy, p,
         t = time-vec2(0,11), I = 4.*d; //cam zoom
    
   
    //Iterate though 400 points and add them to the output color.
    for(float i=-1.; i<1.; i+=0.006)
        {     
        //Xor's neater code!
        p = sin(i*4e4+t.yx+11.)*sqrt((sin(.5*time)+2.5)-i*i), //center piece
        glFragColor += (cos(i+vec4(4,3,2.*sin(t)))+1.)*(1.-p.y) /
        dot(p=I+vec2(i,p/3.)/(p.y+2.),p)/3e4,
        // dot(p=I+vec2(p.x,i)/(p.y+2.),p)/3e4,
        
        p = sin(i*4e4+t.yx+11.)*sqrt(4.-i*i), //towards screen piece
        glFragColor += (cos(i+vec4(4,3,2.*sin(t)))+1.)*(1.-p.y) /
        dot(p=I+vec2(i,p/3.)/(p.y+2.),p)/3e4,
        
        p = sin(i*4e4-t)*sqrt((sin(.5*time)+3.)-i*i), 
        glFragColor += (cos(i+vec4(1,4,6,0))+1.)*(1.-p.y) / 
        dot(p=cos(.5*t)*I+vec2(p.x,i)/(p.y+2.),p)/3e5,
        
        p = sin(i*400.-t+80.)*sqrt(2.-i*i), 
        glFragColor += (cos(i+vec4(2,8,6,0))+1.)*(1.-p.y) / 
        dot(p=I+vec2(p.x,i)/(p.y+2.),p)/3e5,
        
        p = sin(i*4e4-t+4e2)*sqrt(2.-i*i), 
        glFragColor += (cos(i+vec4(2,4,12,0))+1.)*(1.-p.y) / 
        dot(p=sin(.25*t)*I+vec2(p.x,i)/(p.y+2.),p)/3e5;      
        }
}

#version 420

// original https://www.shadertoy.com/view/DdK3zK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//learn from : https://www.shadertoy.com/view/dtf3Ws
void main(void)
{
     // thank for jolle's comment,the extended glow cause great waste!
     //but it doesn't look so natural on the edge
     vec2 d = (gl_FragCoord.xy-resolution.xy*0.5)/resolution.y;
     if (dot(d, d) > 0.1)
     {
     glFragColor = vec4(0.);
     return;
     }
        
     //Clear base color.
    glFragColor-=glFragColor;
    
    vec2 r = resolution.xy, p,
         t = time-vec2(0,11), I = 2.*d;
    
    //Iterate though 400 points and add them to the output color.
    for(float i=-1.; i<1.; i+=6e-3)
        {     
        //Xor's neater code!
        p = cos(i*4e5+t.yx+11.)*sqrt(1.-i*i),
        glFragColor += (cos(i+vec4(4,3,2.*sin(t)))+1.)*(1.-p.y) /
        dot(p=I+vec2(i,p/3.)/(p.y+2.),p)/3e4,
        // dot(p=I+vec2(p.x,i)/(p.y+2.),p)/3e4,
       
        p = sin(i*4e4-t)*sqrt(1.-i*i), 
        glFragColor += (cos(i+vec4(1,4,6,0))+1.)*(1.-p.y) / 
        dot(p=I+vec2(p.x,i)/(p.y+2.),p)/3e5,
        
        p = sin(i*4e4-t+80.)*sqrt(1.-i*i), 
        glFragColor += (cos(i+vec4(2,8,6,0))+1.)*(1.-p.y) / 
        dot(p=I+vec2(p.x,i)/(p.y+2.),p)/3e5,
        
        p = sin(i*4e4-t+4e2)*sqrt(1.-i*i), 
        glFragColor += (cos(i+vec4(2,4,12,0))+1.)*(1.-p.y) / 
        dot(p=I+vec2(p.x,i)/(p.y+2.),p)/3e5;      
        }
}

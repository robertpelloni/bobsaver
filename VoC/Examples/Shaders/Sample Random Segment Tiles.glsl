#version 420

// original https://www.shadertoy.com/view/dtj3WR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// random segments by kastorp
// inspired by  https://www.shadertoy.com/view/Ws3GRs 

//David Hoskins Hash without sin
float hash12(vec2 p)
    {p*=.11;
    vec3 p3  = fract(vec3(p.xyx) * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

float val(vec2 x) { 
    //return .2 *sin(x.x*1.57+.87)+ .2 *sin(x.y*1.57+.87) ; //Gyroid
    return mix(hash12(x+floor(time)), hash12(x+floor(time+1.)),fract(time))*.8-.4; //random
}

#define line(t) smoothstep(max(28./resolution.y,.02),0., abs(t))
float  segment(vec2 v, vec2 b) {return (-v.x*b.y+ v.y*b.x)/length(b);}
float  rcorner(vec2 v,float TK ) { v+=vec2(TK);return length(max(vec2(v.x,v.y),0.0))+min(max(v.x,v.y),0.0) -TK;}

void main(void)
{
	vec2 I = gl_FragCoord.xy;
    vec2 uv = 14.*(I-.5*resolution.xy)/resolution.y;
    vec2 c= floor(uv+.5),lc=fract(uv+.5)-.5,k=vec2(1,0);
    bool odd = mod(c.x,2.)!=mod(c.y,2.); 
    
    if(odd){lc=lc.yx;k=k.yx;} // odd cells are crossed by horizontal line, even cells by a vertical line
    //  each cell has 5 segments
    //         B     
    //         |           
    //         c3            
    //         |---c4--D           
    //         |               
    //         c2  <<this one is excluded        
    // E--c5---|           
    //         |
    //         c1     
    //         |         
    //         A
    
    vec2 a=vec2(val(c),-.5), b=vec2(a.x,+.5),d=vec2(.5,val(c+k)),e=vec2(-.5,val(c-k));
    float flip=1.,mx=d.y,mn=e.y;
    if(e.y>d.y) {flip=-1.; vec2 t=a;a=b;b=t; mx=e.y;mn=d.y;} // if crossing, flip y axis

    //colors
    vec3  lineC1=vec3(step(uv.x,-5.5)),lineC2=vec3(step(5.5,uv.x)),lineC3=vec3(step(-5.5,uv.x)*step(uv.x,5.5)), oddC=vec3(.3,0,0),evenC=vec3(0,.3,0);    
    //if(mouse*resolution.xy.z<=0.) { oddC=evenC=vec3(.3);};
            
    //background
    vec3 col =  (odd? oddC :evenC);  //debug brick color

    //Shane asymmetric blocks 
    float c1=1.,c2=0., c3=1.,c4=1., c5=1.; 
    col += lineC1*(
              line(lc.x - a.x)*( c1* step(lc.y-mn,0. ) 
                       + c2* step(lc.y-mx,0. )* step(0.,lc.y-mn) 
                       + c3* step(0.,lc.y-mx))
           +  line(lc.y - d.y) * c4 * step(0.,lc.x-a.x)
           +  line(lc.y - e.y) * c5 * step(lc.x-a.x,0.)
       );
     float d01 = rcorner(vec2(1,flip)*(-lc+vec2(a.x,d.y)),.0),
           d02 = rcorner(vec2(1,flip)*(lc-vec2(b.x,e.y)),.0); 
     if((min(d01,d02)<.0)^^ odd  ^^ (flip<1.))  col+=lineC1*vec3(.2,.3,.2);  
     
     //skew segments 
     float d1 = segment(lc-d,a-d),
           d2 = segment(lc-e,b-e);
     col += lineC2* ( line(d1)+  line(d2));
     if(((d1<0. && d2<0.) || (d1>0. && d2>0.) )^^ odd  ^^ (flip<1.))  col+=lineC2*vec3(.3,.2,.2);  
     
     
     //rounded corners  
     float d3 = rcorner(vec2(1,flip)*(-lc+vec2(a.x,d.y)),.2),
           d4 = rcorner(vec2(1,flip)*(lc-vec2(b.x,e.y)),.2);    
     col+= lineC3* ( line(d3)+  line(d4));     
     if((min(d3,d4)<.0) ^^ odd  ^^ (flip<1.))  col+=lineC3*vec3(.2,.2,.3);  
     
    glFragColor = vec4(col,1.0);
}


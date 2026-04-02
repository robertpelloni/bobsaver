#version 420

// original https://www.shadertoy.com/view/MdycWK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define hash(p) (fract( sin(p*mat2(63.31,127.63,395.467,213.799)) *43141.59265) )  //thx Fabrice! 

void main(void)
{
    vec2 U = gl_FragCoord.xy;
    vec4 O = glFragColor;
    U = 12.*(U-0.5*resolution.xy)/resolution.x;

    float a, w, v = length(U);
    vec2 h = vec2(ceil(3.*time));
    
    //lines
    for(int i=0; i<21; i++){

        h = hash(h);

        w = 0.03;
        a = (atan(U.x, U.y)+3.14)/6.28*(1.+w);
        v -= sin(smoothstep(h.x,h.x+w,a)*3.14);
    }
     
    //spots
    for(float s=3.; s>.5; s-=.04){
        h = (hash(h)*2.-1.)*s;
           v -= (1.01-smoothstep(0.0,0.5*(3.0-s),length(U-h)));
    }
   
    w = 0.75*fwidth(v); //thx IQ! :)  
    v = smoothstep(-w,w,v);
    
    O = vec4(v,v,v,1);
    glFragColor = O;
}

#version 420

// original https://www.shadertoy.com/view/llc3Ws

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
   vec2 st = uv;
    st=st*2.-1.;
     st.x *= resolution.x/resolution.y;
    ;
    //st += vec2(.0);
    vec3 re ;
    //st*=1.;
    
    
    vec3 color;//vec3(1.);
    int s;
    
    st/=1.328;
    st/=10.;
    for(int i= 0;i<19;i++)
    {
        //st/=2.;
        st*=abs(sin(0.848 + sin(time)/30. ));
        st=fract(st)-0.5;
        
        color += 0.2*(sin(vec3(0.400,0.114,0.064) +  (  1./pow(1.0-smoothstep(0.4, 0.82 , length(st)), 10.)*1. - (1.0-smoothstep(0.36, 0.38 , length(st))) + float(i)*800.*sin(time/1000.)  )  )    );
        st*=2.;
       // s = i/int(re);
       // color=sqrt(color);
    }
    
    glFragColor = vec4(color,1.0);
}

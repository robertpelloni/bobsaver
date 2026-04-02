#version 420

// original https://www.shadertoy.com/view/WtsSzn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

mat2 rot(float a)
{
 return mat2(cos(a), -sin(a), sin(a), cos(a));   
    
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    vec2 qt = uv;
    qt *=  1.0 - qt.yx;
    float vig = qt.x*qt.y*15.;
    vig = pow(vig, 0.15);
    
    
   vec2 st = uv;
   // st.x+=time/100.;
    st=st*2.-1.;
     st.x *= resolution.x/resolution.y;
    ;
    //st += vec2(.0);
    vec3 re ;
    //st*=1.;
    
    
    vec3 color;//vec3(1.);
    int s;
    st = st*2.0-1.;
    //this cool df thing comes from "kig" on shadertoy: https://www.shadertoy.com/view/lll3DB
    float df = pow(abs(st.y+.9)*uv.x*uv.x, 2.9)+pow(abs(st.x+1.)*uv.y*uv.y, 2.);
        //df /= pow(abs(st.y-1.39)*uv.x*uv.x*uv.x*uv.x, .9)+pow(abs(st.x-5.)*uv.y*uv.y, 0.4);

    st *= 1.0+.5*df;
    st.x += time*1.0;
    //st.y += time*1.0;
    
    st/=1.328;
    st/=10.;
    
    for(int i= 0;i<7;i++)
    {
        
        st*=abs(sin(1.48 ));       
        st = st*rot(1.4);
        st = st*rot(1.4);
        st*=abs(sin(2.48 ));
        st = st*rot(1.4);
        st/=abs(sin(10.48 ));
        st = abs(st)*2.0-1.0;
        

        st=fract(st+time/100.)-0.5;
      
        color -= (sin(vec3(0.9400,0.114,0.464) -  (  1./pow(1.0-smoothstep(0.7, 0.72 , length(st)), 1.)*2. - (smoothstep(0.36, 0.38 , length(st))) + float(i)*40.  )  )    );
        st*=2.;
       //s = i/int(re);
       // color=sqrt(color);
    }
    
    glFragColor = vec4(color*vig/1.7,1.0);
}

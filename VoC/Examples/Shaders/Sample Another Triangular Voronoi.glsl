#version 420

// original https://www.shadertoy.com/view/WsV3Dt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Author: bitless
// Title: another triangular voronoi 
// Thanks to Patricio Gonzalez Vivo & Jen Lowe for "The Book of Shaders" and inspiration 

uniform vec2 u_resolution;
uniform vec2 u_mouse;
uniform float u_time;

#define PI 3.1415926

vec2 random2( vec2 p ) {
    return fract(sin(vec2(dot(p,vec2(127.1,311.7)),dot(p,vec2(269.5,183.3))))*43758.5453);
}

vec2 rotate2D(vec2 _st, float _angle,vec2 m){
   
    _st -= m;
    _st =  mat2(cos(_angle),-sin(_angle),
                sin(_angle),cos(_angle)) * _st;
    _st += m;
    return _st;
}

void main(void)
{
    vec2 st = gl_FragCoord.xy/resolution.xy;
    vec2 m = vec2(0.5,0.5); 
    
    if (resolution.y > resolution.x ) {
        st.y *= resolution.y/resolution.x;
        m.y *= resolution.y/resolution.x;
    }       
    else {
        st.x *= resolution.x/resolution.y;
        m.x *= resolution.x/resolution.y;
    }
    vec3 color = vec3(.0);

    st = rotate2D(st,PI*0.666666*((floor(mod(time,15.0)/5.0)-1.0)),m);  //rotation on 120 degrees
    st = rotate2D(st,PI*0.666666*pow(smoothstep(0.0,1.0,mod(time+1.0,5.0))*(1.0-step(1.0,mod(time+1.0,5.0))),2.5),m);  //animate rotation cicle
    // Scale
    st -= m;
    st *= sin(time*0.2)*1.0+3.0+cos(smoothstep(0.0,1.0,mod(time+1.0,5.0))*(1.0-step(1.0,mod(time+1.0,5.0)))*PI*2.0)*0.5; 

    // Tile the space
    vec2 i_st = floor(st);
    vec2 f_st = fract(st);
    
    float m_dist = 9.;  // minimun distance

    vec2 p; 
    vec4 f;
    f.x = 9.;
    
    for(int x=-2;x<=2;x++)
    for(int y=-2;y<=2;y++)
    {    
        p = vec2(x,y); //neightbour
        p += 0.5*sin(time*0.2+6.2831*random2(i_st+p)); //animate
        p += .5  - f_st;

        f.y = max(abs(p.x)*.866 - p.y*.5, p.y); 
        if (f.y < f.x)
        {
            m_dist = f.x;
            f.x = f.y;
            f.zw = p;
        }
        else if( f.y < m_dist )
        {
            m_dist = f.y;
        }
    }
    
    m_dist -= f.x;
    
    vec3 n = vec3(0);
    
    if ( (f.x - (-f.z*.866 - f.w*.5))     <.0001)     n = vec3(0.940,0.860,0.907); 
    if ( (f.x - (f.z*.866 - f.w*.5))    <.0001)     n = vec3(0.970,0.949,0.888);
    if ( (f.x - f.w)                    <.0001)     n = vec3(0.871,0.900,0.960);
    
    color =  n*(0.6+length(f.x)); //base color + distance field shadow
    color -= 0.45*pow(clamp(m_dist*4.0,0.0,1.0),0.2); //edges
    color *= 1.0-smoothstep(0.0,10.0,mod(length(f.x)*100.0,15.0))*0.06; //gradient stripes
    color *= 1.0-step(2.0,mod(length(f.x)*100.0,15.0))*0.05; //thin light stripes

    glFragColor = vec4(color,1.);
}

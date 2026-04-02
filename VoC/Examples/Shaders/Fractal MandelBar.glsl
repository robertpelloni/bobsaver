#version 420

// original https://www.shadertoy.com/view/XtSczh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 rotate(vec2 p, float ang){
    float c = cos(ang), s = sin(ang);
    return vec2(p.y * c - p.x * s, p.y * s + p.x * c);
}

float hash( vec2 p ) {
    float h = dot(p,vec2(127.1,311.7));    
    return fract(sin(h)*4758.5453123);
}

float noise( in vec2 p ) {
    vec2 i = floor( p );
    vec2 f = fract( p );    
    vec2 u = f*f*(3.0-2.0*f);
    return -1.0+2.0*mix( mix( hash( i + vec2(0.0,0.0) ), 
                     hash( i + vec2(1.0,0.0) ), u.x),
                mix( hash( i + vec2(0.0,1.0) ), 
                     hash( i + vec2(1.0,1.0) ), u.x), u.y);
}

void main(void)
{
    vec2 position = 4.0*( gl_FragCoord.xy / resolution.xy )-2.0 ;
    

    
    float v=0.0;
    float ii=0.0;
    float rg=1.0;
    int f=0;

    // White    
    for(int i=0;i<20;i++)
    {
        vec2 n1=rg*vec2(sin(time+ii),cos(time+ii));
        vec2 n2=rg*vec2(cos(time+ii),sin(time+ii));
        vec2 pos=vec2(noise(n1)*2.0,noise(n2)*2.0);
        float l1 = 0.1/length(pos - position);
        if( f==0 )
        {
            v+=l1;
            f=0;
        }
        ii+=0.1;
    }
    
    
    vec2 r=rotate(position,time);
    r*=1.0+sin(time)/4.0;    // black
    float zim=0.0;
    float zre=0.0;
    float cre=r.x;
    float cim=r.y;
    float ite=0.0;
    for(int i=0;i<32;i++)
    {
        ite++;
        float dam=zre*zre-zim*zim+cre;
        zim=(abs(3.0*sin(time/10.0)))*zre*zim+cim;
        zre=dam;
        if( (zre*zre+zim*zim)>4.0)
            break;
    }
    v=pow(v,2.0);
    if(ite>30.0)
    {
        float rcolor = 0.0;
        float gcolor = 0.0;
        float bcolor = 0.0;
        float rg=0.5;
        float an=time*48.0;
        float ck=16.0+16.0*resolution.x;
    
        for(float i=0.0;i<16.0;i++)
        {
            float di=0.08;
            float y=rg*sin( (an+i*10.0)*3.141/180.0);
        
            if( position.y>y-di && position.y<y+di )
            {
                float c=1.0-abs(position.y-y)*10.0;
                
                rcolor=c;
                gcolor=rcolor*(i/ck);
                bcolor=rcolor*(i/ck);
            }
        
        }    
        
        glFragColor = vec4( vec3( rcolor, gcolor , bcolor  ), 1.0 );
    }
    else
    {
        v=(ite+v)/32.0;
        glFragColor = vec4(vec3(v),1.0);
    }    
 
}

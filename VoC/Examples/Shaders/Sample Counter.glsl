#version 420

// counter. (c) Fabrice NEYRET June 2013

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;
uniform sampler2D backbuffer;

out vec4 glFragColor;

#define STYLE 2
#define E (1./6.)

vec2 pos,scale;

int aff(int b) // display digit b at pos with size=scale
               // 1:pixel on   0: pixel off    -1: out of digit bbox
{
    bool c; // pixel is in a set segment.
    vec2 uv = (gl_FragCoord.xy-pos)/scale; // normalized coordinates in char bbox
    pos.x -= 1.2*scale.x;
    if((abs(uv.x)<.5)&&(abs(uv.y)<.5*(1.-E)))     // pixel is in bbox
    {
        const float dy = 2.*(1.-E);
        float ds = 1./sqrt(1.+dy*dy)*3./1.414/(1.-2.*E);
        vec2 st = 1.5+ds*vec2(uv.x-dy*uv.y,-uv.x-dy*uv.y); // in diamons frame coords
        int seg = int(st.x)+3*int(st.y);
        uv = 2.*(st-floor(st))-1.;               // pixel in segment coords
        uv = vec2(uv.x-uv.y,uv.x+uv.y)/sqrt(2.); // same but parallel to screen
#if 1
        if     (b==0) c = (seg!=4);              // digit b to segment seg
        else if(b==1) c = (seg==1)||(seg==5);
        else if(b==2) c = (seg!=3)&&(seg!=5);
        else if(b==3) c = (seg!=3)&&(seg!=7);
        else if(b==4) c = (seg!=0)&&(seg!=7)&&(seg!=8);
        else if(b==5) c = (seg!=1)&&(seg!=7);
        else if(b==6) c = (seg!=1);
        else if(b==7) c = (seg==0)||(seg==1)||(seg==5);
        else if(b==8) c =   true;
        else if(b==9) c = (seg!=7);
#else
        c = (seg==b);
#endif
#if STYLE==1
        if (c)    if (length(uv)<1.) return 1; // pixel in a set segment
        else    if (length(uv)>.9) return 1;            
#elif STYLE==2
        if (4*(seg/4)==seg) uv.y *=4.;
        else                uv.x *=4.;
        if (c)    if (length(uv)<1.3) return 1; // pixel in a set segment    
#endif
        return 0; // pixel in digit bbox but out of set segment
    }
    return -1;    // pixel out of digit bbox
}

void main(void)
{
    pos   = vec2(.85*float(resolution.x), .50*float(resolution.y));
    scale = vec2(.25*float(resolution.y),.375*float(resolution.y));

    int c=0;
    
    int t = int(time*100.); // decompose 100*time in digits 
    for (int i=0; i<5; i++) {
        int n = t-10*(t/10); t=t/10;
        c = aff(n);      // true if pixel in the digit bbox AND in a set segment 
        if (c>=0) break; // digit under pixel found
    }
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    if (c>0) 
        glFragColor = vec4(0.5+0.5*sin(time),uv,1.0);
    else
        glFragColor = vec4(uv,0.5-0.5*sin(time),1.0);
}

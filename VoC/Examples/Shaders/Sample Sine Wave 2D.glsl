#version 420

// original https://www.shadertoy.com/view/sd2Gzh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//2D version of https://www.shadertoy.com/view/tsKSzR
//Original by skaplun

//I tried to match it just by looking

//I tried to match the perspective for fun but it got kinda tedious so
//it's not perfect.

#define pi 3.141592653
void main(void)
{
    float t = time*1.0;
    vec2 R = resolution.xy;
    vec2 uv = (gl_FragCoord.xy-.5*R.xy)/R.y;
    uv.y=-uv.y;
    float y0 = uv.y;
    float y1 = uv.y;
    
    float wc = 130.0;
    float aa = 0.005*(450.0/max(resolution.y,450.0)); 
    float w = 0.0035; //width
    w-=aa; 
    
    for(int i = 0; i<int(wc); i++){
        float fi = float(i);
        
        y1=uv.y+1.1-2.5*(pow(fi/9.0,2.0)/300.0);

        float x = uv.x*4.4+1.8*sin(fi/11.0+t)*((fi*3.3)/300.0);
        
        float h;
        h = 3.5*sin((fi/11.0)+t);
        
        //Try these too
        //h = 3.5*sin((fi/11.0)+t)*sin((fi/11.0)+t);
        //h = 3.5*abs(sin((fi/11.0)+t));
        
        y1+=h*(cos(x*pi)+1.0)*0.05*step(-1.0,x)*step(x,1.0);
        
        y0 = y0*smoothstep((y1+w)+aa,(y1+w)+aa*3.0,0.4)  
        +(y1-w)*smoothstep(0.4,0.4+aa,(y1-w)+aa);    
    }
    
    //This is bad but I'm to stupid to fix it.
    y0=1.0-y0;
    y0=smoothstep(y0-0.4,y0,0.6);
    y0=1.0-y0;

    glFragColor = vec4(vec3(y0),1.0);
}

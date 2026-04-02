#version 420

#define PI 3.1415
#define maxIter 128

uniform float mouse;
uniform float time;
uniform vec2 resolution;

out vec4 glFragColor;

uniform sampler2D backbuffer;

#define t2(D) texture2D(backbuffer, (gl_FragCoord.xy+D)/resolution)-1./128.
#define t3(D) ((t2(D+vec2(.5))+t2(D-vec2(.5))+t2(D+vec2(.5,-.5))+t2(D-vec2(.5,-.5)))/4.)
#define t4(D) ((t3(D+vec2(.25))+t3(D-vec2(.25))+t3(D+vec2(.25,-.25))+t3(D-vec2(.25,-.25)))/4.)

void main( void ) {

    float r=0.,g=0.,b=0.;//plz
    
vec2  surfacePos = (gl_FragCoord.xy - resolution.xy*.5) / resolution.y;
    vec2 c = -10.*surfacePos.yx/cos(time/8.+5.*dot(surfacePos, surfacePos) + pow(length(surfacePos), -0.33));
    c = c*2.;
    vec2 z = vec2(0);
    
    float I = 0.;
    
    for(int i=1; i<maxIter; i++)
    {
        z = vec2(pow(z.x, 2.)-pow(z.y, 2.),z.x*z.y*2.)+c;
        if(length(z)>32.)
        {
            //float zn = z.x*z.x+z.y*z.y;
            float zn=length(z);
            I=float(i);
            I=mod(sqrt(I+1.0-log2(log2(zn)))*.15,1.0);
            break;
        }
    }
    
    if(I>0.)
    {
        //float roff=0.95; float goff=0.9; float boff=2.1;
        //float rexp=1.8; float gexp=0.9; float bexp=0.7;
        //float rexp=2.7; float gexp=1.5; float bexp=2.;
        
        //r = -4.*pow(pow(mod(I+roff,1.),rexp)-0.5,2.)+1.;
        //g = -4.*pow(pow(mod(I+goff,1.),gexp)-0.5,2.)+1.;
        //b = -4.*pow(pow(mod(I+boff,1.),bexp)-0.5,2.)+1.;
        
        //r = pow(r,1.2)*1.;
        //g = pow(g,2.8)*1.;
        //b = pow(b,1.3)*1.;
        
        I = I + 0.3;
        
        r = .5 + .5 * cos(PI*2.*I);
        g = .5 + .5 * cos(PI*2.*(I+.1));
        b = .5 + .5 * cos(PI*2.*(I+.2));
    }
    
    glFragColor = max(t4(-2.*normalize(surfacePos)), vec4( r, g, b, 1 ));

}

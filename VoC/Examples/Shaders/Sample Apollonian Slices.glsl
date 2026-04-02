#version 420

// original https://www.shadertoy.com/view/XtGSR1

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void) {
    float MinRes = min(resolution.x,resolution.y);
    float MaxRes = max(resolution.x,resolution.y);
    
    float h = sin(-time*.1)*.495+.5;//Slice Height
    
    float Scale = (1.-h);//Slice width is basically proportional to slice height
    //Set this is 1 to remove the zoom in
    
    vec2 sp = (gl_FragCoord.xy*2.-resolution.xy)/MinRes*Scale;//Scaled view space
    
    vec3  p = vec3(sp.x,h,sp.y);//get the point in the 3D Slice
   
    //Apply Apollonian fractal formula on p
    float s = 1.;
    for( int i=0; i<16;i++ ){
        p = mod(p+1.,2.)-1.;
        float k = 1.03/dot(p,p);
        p *= k;
        s *= k;
    }
    //aquire distance
    float d = .25*abs(p.y)/s;
    
    //color distance with an appropriate smoothstep scaled in view resolution and view space
    glFragColor = vec4(smoothstep(MinRes*10./Scale,0.,1./d));
}

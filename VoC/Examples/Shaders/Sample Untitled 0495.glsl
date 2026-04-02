#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float sphsize=.3;

const float dist=.67;
const float perturb=0.3;

const float displacement=.015;
const float windspeed=.3;

const float steps=110.;
const float stepsize=.025; 

const float brightness=.23;
const vec3 planetcolor=vec3(0.55,0.4,0.3);
const float fade=.004;
const float glow=20.0;

// fractal params
const int iterations=13; 
const float fractparam=.7;
const vec3 offset=vec3(1.5,2.,-1.5);

float wind(vec3 p) 
{
    float d=max(0.,dist-max(0.,length(p)-sphsize)/sphsize)/dist;
    float x=max(0.2,p.x*2.);
    p.y*=1.+max(0.,-p.x-sphsize*.25)*1.5;
    p-=d*normalize(p)*perturb;
    p+=vec3(time*windspeed,0.,0.);
    p=abs(fract((p+offset)*.1)-.5);
    for (int i=0; i<iterations; i++) 
        p=abs(p)/dot(p,p)-fractparam;
    return length(p)*(1.+d*glow*x)+d*glow*x;
}

void main( void ) {

    vec2 uv = ( gl_FragCoord.xy / resolution.xy ) - 0.5;
    vec3 dir=vec3(uv,1.);
    
    dir.x*=resolution.x/resolution.y;
    vec3 from= vec3(0.,0.,-2.+stepsize);
    
    // volumetric rendering
    
    float v=0., l=-0.0001, t=time*windspeed*.4;
    
    for (float r=10.;r<steps;r++) 
    {
        vec3 p=from+r*dir*stepsize;
        float tx = displacement;
        
        if (length(p)-sphsize-tx>0.)
            v+=min(80.,wind(p))*max(0.,2.5-r*fade); 
        else if (l<0.) 
            l=pow(max(.53,dot(normalize(p),normalize(vec3(-1.,.5,-0.3)))),4.)*(.5+(1.+p.z*.5)+vec2(tx+t*.5,0.)).x*2.;
    }
    
    v/=steps; v*=brightness;
    vec3 col=vec3(v*1.25,v*v,v*v*v)+l*planetcolor;
    col*=1.-length(pow(abs(uv),vec2(5.)))*44.;

    glFragColor = vec4(col, 1.0 );

}

#version 420

// original https://www.shadertoy.com/view/NlyGzm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// optical illusion inspired from @coachly.de
// the discs are not changing in size at all.
// slight variation of this can give the illusion of movement

#define PI 3.14159

void main(void)
{
    vec2 position = mod( gl_FragCoord.xy/resolution.xy, vec2(.5,1.) );
        
    float angle = (atan(position.y-.5,position.x-.25)+PI)/2./PI;
    angle = mod(angle+time*2.4,1.);
    
    float r=.5,g=.5,b=.5,l=length(position-vec2(.25,.5));
    
    if(l>.13&&l<.2) {
        if ( angle<.25) {  // y to r
            g=angle*4.;
            r=1.;
            b=0.;
        }            
        else if(angle<.5) {  // c to y
            g=1.;
            b=(angle-.25)*4.;
            r=1.-b;
        }
        else if(angle<.75) { // b to c
            b=1.;
            g=1.-(angle-.5)*4.;
            r=0.;
        }
        else {        // r to b
            r=(angle-.75)*4.;
            b=1.-r;
            g=0.;
        }
    }
    
    if(l>.1975&&l<.2) {    // outer rim
        float s = .3 + abs(cos(PI*angle-.03*mod(time,1.)));
        s*=s; r*=s; g*=s; b*=s;
    }
    else if(l>.127&&l<.13) {    // inner rim
        float s = .3 + abs(sin(PI*angle-.03*mod(time,1.)));
        s*=s; r*=s; g*=s; b*=s;
    }

    /*if(l>.1975&&l<.2) {    // outer rim
        float s=1.3*abs(sin(PI*angle-sin(time)));
        r*=s; g*=s; b*=s;
    }
    else if(l>.127&&l<.13) {    // inner rim
        float s=1.3*abs(sin(PI*angle+sin(time*1.23456)));
        r*=s; g*=s; b*=s;
    }*/
    
    glFragColor = vec4(r,g,b,1);
}

#version 420

uniform vec2 resolution;
uniform float time;

out vec4 glFragColor;

void main( void ) 
{
    vec2 p = ( gl_FragCoord.xy / resolution.xy ) * 2.0 - 1.0;
    float persp=(1.5+gl_FragCoord.x / resolution.x)/2.;
    float wave=1.0+sin(2.*p.x-time*4.);
    float ripple=(1.+sin(21.*p.x-time*14.))/4.;
    float rippleshading=(1.+sin(21.*p.x-time*14.*3.14/4.))/6.;
    float shading=1.- rippleshading*(1.+cos(p.y+time))/4.-wave/5.;
    p.y-= sin(2.*p.x+time)/16.+ wave/13. + ripple/32.- gl_FragCoord.x / resolution.x/16.*(2.+sin(time*6.));
    p.x+= sin(2.*p.y+time)/26.+ wave/13. ;
    p.x*=persp;
    p.y*=persp;
    float d = -p.x * sign(p.y) + p.y * sign(p.x);
    
    vec4 kRed = vec4( 204.0 / 255.0, 0.0, 0.0, 1.0 );
    vec4 kWhite = vec4( 1.0, 1.0, 1.0, 1.0 );
    vec4 kBlue = vec4( 0.0, 0.0, 102.0 / 255.0, 1.0 );
    
    if(p.x>1.-gl_FragCoord.x / resolution.x/6.) {
        glFragColor = kWhite;
    }
    else if(p.x<-1.+gl_FragCoord.x / resolution.x/6.) {
        glFragColor = kWhite;
    }
    else if(p.y>1.-gl_FragCoord.y / resolution.y/6.) {
        glFragColor = kWhite;
    }
    else if(p.y<-1.-gl_FragCoord.y / resolution.y/1.) {
        glFragColor = kWhite;
    }
    else if((abs(p.x) < (6.0/60.0)) || (abs(p.y) < (6.0/30.0)))
    {
        glFragColor = kRed*shading;
    }
    else 
    if((abs(p.x) < (10.0/60.0)) || (abs(p.y) < (10.0/30.0)))
    {
        glFragColor = kWhite*shading;
    }
    else 
    if( (d > 0.0)  && (d < 0.15))
    {
        glFragColor = kRed*shading;
    }
    else
    if( (d > -0.15 * 3.0 / 2.0)  && (d < 0.15 * 3.0 /2.0))
    {
        glFragColor = kWhite*shading;
    }
    else
    {
        glFragColor = kBlue*shading;
    }
}

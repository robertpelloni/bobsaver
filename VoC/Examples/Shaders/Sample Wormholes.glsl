#version 420

// original https://www.shadertoy.com/view/DsjSzt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
    "Wormholes" by @XorDev
    
    
    
    Tweet: twitter.com/XorDev/status/1601770313230209024
    Twigl: t.co/k5mZbAg1ox
*/
void main(void) //WARNING - variables void (out vec4 O, vec2 I) need changing to glFragColor and gl_FragCoord.xy
{
    //Clear frag color
    vec4 O = vec4(0.);
    //Resolution for scaling
    vec2 r = resolution.xy;
    //Initialize the iterator and ring distance
    for(float i=0.,d;
    //Loop 50 times
    i++<5e1;
    //Add ring color, with ring attenuation
    O += (cos(i*i+vec4(6,7,8,0))+1.)/(abs(length(gl_FragCoord.xy-r*.5+cos(r*i)*r.y/d+d/.4)/r.y*d-.2)+8./r.y)*min(d,1.)/++d/2e1 )
        //Compute distance to ring
        d = mod(i-time,5e1)+.01;
	glFragColor=O;
}

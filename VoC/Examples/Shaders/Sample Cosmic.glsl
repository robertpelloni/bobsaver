#version 420

// original https://www.shadertoy.com/view/msjXRK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
    "Cosmic" by @XorDev
    
    I love making these glowy shaders. This time I thought I'd try using discs instead.

    Tweet: twitter.com/XorDev/status/1601060422819680256
    Twigl: t.co/IhRk3HX4Kt
    
    <300 chars playlist: shadertoy.com/playlist/fXlGDN
*/
void main(void)
{
	vec2 I=gl_FragCoord.xy;
    //Clear fragcolor (hacky)
    vec4 O = vec4(0.0);
    //Initialize resolution for scaling
    vec2 r=resolution.xy,
    //Save centered pixel coordinates
    p = I-r*.6;
    
    //Initialize loop iterator and arc angle
    for(float i=0.,a;
        //Loop 300 times
        i++<3e1;
        //Add with ring attenuation
        O += 5e-3 / (abs(length(I=p*mat2(1,-1,2,2)/(r.y-p-p.yx))-i/4e1)+1./r.y)*
        //Limit to arcs
        clamp(cos(a=atan(I.y,I.x)*ceil(i*.1)+time*sin(i*i)+i*i),.0,.6)*
        //Give them color
        (cos(a-i+vec4(0,1,2,0))+1.) );
	glFragColor = O;        
}

#version 420

// original https://www.shadertoy.com/view/ltdfR7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define nTime (time*0.5)+1000. // speed

float DDot(vec2 p1,vec2 p2) {
    return 1.3-(distance(p1,p2)*300.);
}

float Wobble(float i,float factor) {
    float wob1 = sin((i+nTime+i+i)*10.)/10.+sin(nTime/3.)/85.+sin(nTime/5.)/85.;
    float wob2 = sin((i+nTime+i+i)*10.)/10.+sin((i+nTime)*3.)*0.5+sin((i+nTime)*5.)*0.4; 
    return mix(wob2,wob1,factor);
}

float Curv(float i,float ii) {
    return(cos((nTime/3.)+ii+ii)*(sin((i*ii+i)*(i+6.))/(7.*atan(nTime/3.))));
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;

    float factor = 0.3;
    float ii=1.+(sin(nTime/20.));
    vec3 col1=vec3(0.);
    
    for (float i=0.00; i<= 1.05;i+=0.004) {
    
           vec2 cc= vec2(i+Curv(i,i+sin(time+ii)),(Wobble(i,factor)+Curv(i,ii)*4.));
        float col = DDot(uv, (cc * vec2(1.,factor)) + vec2(0.,0.5) );
        vec3 col2 = vec3(col * ii, col*(sin(i)+.5),col*(sin(ii)+.5));
        col1 = max(col2,col1);

    }
    glFragColor = vec4(col1,0.);
}

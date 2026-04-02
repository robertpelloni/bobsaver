#version 420

// original https://www.shadertoy.com/view/XltBR8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float DDot(vec2 p1,vec2 p2) {
    return 1.3-(distance(p1,p2)*300.);
}

float Wobble(float i) {
    return sin((i+time+i+i)*10.)/10.+sin(time/3.)/85.+sin(time/5.)/85.;   
}

float Curv(float i,float ii) {
    return(cos((time/3.)+ii+ii)*(sin((i*ii+i)*(i+6.))/(7.*atan(time/3.))));
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    //vec2 uv = (gl_FragCoord-0.5*resolution.xy)/resolution.y;
    
    vec3 col1=vec3(0.);
    
    for (float i=0.00; i<= 1.05;i+=0.004) {
    
        for (float ii=1.0; ii<=3.; ii++) {
               float col = DDot(uv, vec2(i+Curv(i,i+sin(time+ii)),0.5+(Wobble(i)+Curv(i,ii)*4.)));
            vec3 col2 = vec3(col * ii, col*(sin(i)+.5),col*(sin(ii)+.5));
            col1 = max(col2,col1);
        }
    //col1 = max(max(col,m),col1);
    }
    glFragColor = vec4(col1,0.);
}

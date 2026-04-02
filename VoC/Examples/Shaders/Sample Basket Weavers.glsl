#version 420

// original https://www.shadertoy.com/view/lltfDN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define S(a,b,t) smoothstep(a,b,t)
#define WD 2.
#define nTime (time*0.4)+5000.
#define FACT vec2(0.28,0.2)

float Dline(vec2 p, vec2 a, vec2 b) {
    // line drawing function from BigWings
    vec2 pa = p-a;
    vec2 ba = b-a;
    float t = clamp(dot(pa,ba)/dot(ba,ba), 0.0, 1.1);
    return length(pa-ba*t);
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (gl_FragCoord.xy-0.5*resolution.xy)/resolution.y;

    // Time varying pixel color
    vec3 col = vec3(0.); // vec3(.6,.9,.02);
    
    for ( float i = 0.; i<8.; i+=0.1)
    {
    for ( float ii = 0.; ii<9.; ii+=2.)
    {
    float d1a = sin(nTime+i)+cos(ii/2.);
    float d1b = sin(nTime+i)+cos(ii/2.);
    float d1 = mix(d1a,d1b,sin(nTime/9.)+0.5);
    float d2 = sin(nTime-ii)-cos(i);
    float d3 = cos(nTime/(1.+mod(14.,nTime/40.)))+sin(sin(nTime/(0.1+mod(15.,nTime/5.)))+i-ii);
    float d4 = cos(nTime*ii)*sin(nTime+i);
    
    float d = Dline(uv, vec2(d1,d2)*FACT, vec2(d3,d4)*FACT);

    float m = S(WD/200., (WD/200.)-(0.02), d)*WD;
    
    float col1 = (cos(nTime+ii)/2.+0.6);
    float col2 = (sin((ii+nTime))/2.+0.5);
   // float col3 = (cos((i+nTime)/9.)/ii+0.5);
        
    col = max(col,vec3(m*col1,m*col2,m*col2));
    }
    }
    
    // Output to screen

    glFragColor = vec4(col,1.0);
}

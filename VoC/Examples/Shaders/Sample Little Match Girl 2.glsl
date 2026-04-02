#version 420

// original https://www.shadertoy.com/view/XtdfD8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define S(a,b,t) smoothstep(a,b,t)
#define WD 2.
#define nTime (time*0.6)+500.
#define FACT vec2(0.2,0.2)

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
    
    for ( float i = 0.; i<10.; i+=0.5)
    {
    for ( float ii = 0.; ii<10.; ii+=0.6)
    {
    float d1 = sin(ii+nTime)+cos(i);
    float d2 = sin(nTime)-cos(i);
    float d3 = cos(nTime+i);
    float d4 = cos(nTime+ii)+sin(nTime+ii);
    
    float d = Dline(uv, vec2(d1,d2)*FACT, vec2(d3,d4)*FACT);

    float m = S(WD/200., (WD/200.)-(0.02), d)*WD;
    
    float col1 = (cos(nTime+ii)/2.+0.6);
    float col2 = (sin((ii+nTime))/2.+0.5);
    float col3 = (cos((i+nTime)/9.)/ii+0.5);
        
    col = max(col,vec3(m*col1,m*col2,m*col2));
    }
    }
    
    // Output to screen

    glFragColor = vec4(col,1.0);
}

#version 420

// original https://www.shadertoy.com/view/fljyDt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Initial Version: Apr 20, 2022

float PI = 3.14159256;

void main(void)
{
    vec2 uv = ( gl_FragCoord.xy - .5* resolution.xy ) /resolution.y;
    vec3 col = vec3(0);

    // Outermost Ring (doesn't move)
    float d = distance(uv, vec2(0.,0.));  
    float radius = .40;
    vec3 ringCol1 = vec3(pow(19.,-abs(d-radius)*20.));   
    col += ringCol1-1.1;
    
    // Inner Rings
    vec2 cPrev = vec2(0.,0.);
    float numRings = 8.;
    float ringDelta = .04;
    for(float i=0.; i<numRings; i++){
      vec2 cCurrent = vec2(ringDelta*sin((i/2.+1.)*time),ringDelta*cos((i/2.+1.)*time)) + cPrev;
      d = distance(uv, cCurrent);
      radius = .35 - i*ringDelta;
      vec3 currRing = vec3(pow(19.,-abs(d-radius)*12.));
      col += currRing;      
      cPrev = cCurrent;    
    }

    // Output to screen
    glFragColor = vec4(col,1.0);
}

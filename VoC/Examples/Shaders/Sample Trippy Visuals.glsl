#version 420

// original https://www.shadertoy.com/view/tlyXzw

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

bool swi = false;
float speed = 1.;

float getAnim(float t){
    return tan(speed*t)*1.;
}

float farbe(float t){
    float anim = cos(speed*t);
    if(abs(anim)==1.)
       swi = swi ? false : true;
        
    if(swi)
        return (anim<0.?1.:-1.);
    else
        return (anim>=0.?1.:-1.);
}

vec2 ri = vec2(0.25,0.25);

void main(void)
{
    vec2 uv = ( gl_FragCoord.xy - .5*resolution.xy) /resolution.y;
    float aspect = resolution.x/resolution.y;
    float betrag = length(vec2(uv.x,uv.y));
    float winkel = atan(uv.x,uv.y);
    float r = abs(sin((time*0.25+winkel)*10.+cos((betrag+time)*5.)*2.));
    float g = sin(winkel*10.+cos((betrag-time)*5.)*2.);
    float b = abs(sin((r*3.14)/(1.5+sin(time))));
    

    // Output to screen
    glFragColor = vec4(0.7*r,g,1.2*b,1.0);
}

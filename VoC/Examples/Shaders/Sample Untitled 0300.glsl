#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159265359

float plot(vec2 p, float y, float thick){
    return  smoothstep( y-thick, y, p.y) - smoothstep( y, y+thick, p.y);
}

float plot(vec2 p, float y){
    return plot(p,y,0.02);
}

void main( void ) {
    
    vec2  surfacePos = (gl_FragCoord.xy - resolution.xy*.5) / resolution.y;
    vec2 p = surfacePos;
    vec3 c = vec3(0);
    p *= 2.;
    p.y += 0.5;
    c.r += plot(p,pow(p.x,2.));
    
    c.g += plot(p,pow(p.x,2.)+pow(p.y,2.0));
    p.y += -1.;
    c.r += plot(p,pow(p.x,4.0)-pow(p.x,2.0));
    
    p.y += 0.75;
    c.b += plot(p,pow(p.x,2.));
    p.y += -0.5;
    c.b += plot(p,-pow(p.x,2.));

    p.y += .5;
    c.b += plot(p,pow(p.x*1.5,2.)+pow(p.y*1.5,2.0));
    
    vec2 look = vec2(0);
    look.x = cos(mouse.x*PI);
    look.y = cos(mouse.y*PI);
    vec2 clampv = abs(normalize(look)*0.12);
    look = clamp(look,-clampv,clampv);
    
    p.y += -.18;
    vec2 look2 = -mouse+0.5;
    vec2 clampv2 = abs(normalize(look2)*0.12);
    look2 = clamp(look,-clampv2,clampv2);
    
    p += look2;
    c += plot(p,pow(p.x*3.,2.)+pow(p.y*3.,2.0));

    glFragColor = vec4(c,1.0);

}

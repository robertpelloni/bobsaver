#version 420

// original https://www.shadertoy.com/view/NsB3zK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define pi 3.14159265359

float segdf(vec2 p, vec2 a, vec2 b ) {
    vec2 pa = p - a;
    vec2 ba = b - a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0., 1. );
    return length( pa - ba*h );
}

vec2 loop (float t, float div, float i){

return 0.25*vec2(sin(t+(i+1.0)*pi/div)*2.0,0.5*cos(t+(i+1.0)*pi/div));

}
void main(void)
{
    vec2 R = resolution.xy;
    vec2 uv = (gl_FragCoord.xy-.5*R.xy)/R.y;
    float t = time;
    vec3 col =vec3(0.0);
    float occlude = 1.0; //Change to 0.0 to see all the lines
    
    float sides = 3.0 + floor((sin(t*1.2)*0.5+0.5)*5.);
   // sides =3.;
    for(float i = 0.0; i<sides;i++){
        float div = sides/2.0;

        vec2 loop1 = loop(t,div,i-1.);
        vec2 loop11 = loop(t,div,i);
        vec2 loop111 = loop(t,div,i-2.);
        loop1.y+=.30;
        loop11.y+=.30;

        vec2 loop2 = loop(t,div,i-1.);
        vec2 loop22 = loop(t,div,i);
        loop2.y-=.35;
        loop22.y-=.35;

        vec3 glowcol = vec3(fract(t/5.+0.333),fract(t/5.+0.666),fract(t/5.));
        float num = 200.0+(1.0+sin(t*5.0))*200. +10.*sides;

        //BOTTOM
        float glow = abs(1.0 / (num * segdf(uv,loop2,loop22)));
        col += vec3(glow)*(glowcol+1.0) * (step(loop22.y+loop2.y,-.7*occlude));
        //SIDES
        glow = abs(1.0 / (num * segdf(uv,loop1,loop2))); 
        if((loop1.x>loop11.x || loop1.x<loop11.x && loop1.x<loop111.x)||occlude == 0.0){
        col +=vec3(glow)*(glowcol+1.0);
        }
        //TOP
        glow = abs(1.0 / (num * segdf(uv,loop1,loop11)));
        col +=vec3(glow)*(glowcol+1.0);
    }
    
    glFragColor = vec4(col,1.0);
}

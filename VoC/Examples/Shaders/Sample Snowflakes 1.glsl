#version 420

//--- snowflakes ---
// by Catzpaw 2016

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 hash(vec2 p){return fract(cos(mat2(42.,87.,49.,61.)*p)*13.);}
float plot(vec2 p,float v){return smoothstep(v-0.075,v,p.y)-smoothstep(v,v+0.01,p.y);}

void main( void ) {
    vec2 uv=(gl_FragCoord.xy*2.-resolution.xy)/resolution.y; 
    vec3 finalColor=vec3(0);
    vec2 p,h;
    finalColor+=vec3(abs(uv.y*.5));
    for(float i=-0.;i<20.;i++){
        h=hash(vec2(i))*(resolution.x/resolution.y);
        p=vec2(uv.x+h.x-h.y+sin(time*h.x)*(h.y*.4-.2),mod(uv.y-i*.1+time/3.,2.)-1.);
        float r=length(p)*2.,a=atan(p.y,p.x)+time*(h.y*.2-.1)*5.,f=abs(sin(a*3.)*cos(a*12.))*.1+.05;
        finalColor+=vec3(plot(vec2(a,r),f));
    }
    glFragColor = vec4(finalColor,1);
}

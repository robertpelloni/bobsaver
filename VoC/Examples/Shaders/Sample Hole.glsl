#version 420

//--- hole
// by Catzpaw

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

mat2 rot(float phi) {
    return mat2(cos(phi), -sin(phi), sin(phi), cos(phi));    
}

void main(void){
    vec2 uv=(gl_FragCoord.xy*2.-resolution.xy)/min(resolution.x,resolution.y); 
    vec3 finalColor;
    float phi = atan(uv.x,uv.y)/3.14/2.+0.5;
    float s=sin(time*.7)*.5+.5;
    float r=length(uv) + sin((phi+ time*0.3)*100.)*0.05;
    float r1=length(uv) + sin((phi- time*0.3)*100.)*0.05;
    float g=sin(time*.7)*.5+0.1;
    if(r>s){
        uv*=smoothstep(s,s*s+r,r);
        finalColor=vec3(.4);
    }else
    if(r1 > g){
        uv*=smoothstep(g,g*g+r,r);
        uv = rot(-time*0.3)*uv;
        finalColor=vec3(0.,0.,0.7);    
    }else{
        uv = rot(-time*0.3)*uv;
        finalColor=vec3(.8,0,0);
    }

    finalColor*=vec3(step((sin((uv.x-0.204)*100.)+sin((uv.y+0.11)*100.))*100.,.5)*.3+.4);
    glFragColor = vec4(finalColor,1);
}

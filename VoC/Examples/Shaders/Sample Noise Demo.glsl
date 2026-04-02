#version 420

// original https://www.shadertoy.com/view/WdScDt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float rand(vec2 p){
    return fract(sin(p.x*102.33+p.y*3623.42)*27827.);
}

float smoothrand(vec2 p){
    vec2 lv = fract(p);
    vec2 id = floor(p);
    
    lv = lv*lv*(3.-2.*lv);
    
    float b = mix(rand(id),rand(id+vec2(1.,0.)),lv.x);
    float t = mix(rand(id+vec2(0.,1.)),rand(id+vec2(1.,1.)),lv.x);
    
    return mix(b,t,lv.y);
}

float noise(vec2 p,uint depth){
    float c=0.;
    float amp=1.;
    float a=0.;
    for(uint i = 0U;i<=depth;i++){
        c+=smoothrand(p+vec2(amp*float(i),a*float(i)))*amp;
        
        p*=2.;
        a+=amp;
        amp/=2.;
    }
    return c / a;
}

void main(void)
{
    vec2 uv = (2.*gl_FragCoord.xy-resolution.xy)/resolution.y;
    uv-=vec2(0.6,0.);
    float len = length(uv);
    float v = 0.5+noise((uv/len+vec2(time))*2.,3U)*0.5;
    vec3 col = vec3(smoothstep(v-0.005,v,len));
    
    
    //vec3 col = vec3(noise(uv,10U));
    // Output to screen
    glFragColor = vec4(col,1.0);
}

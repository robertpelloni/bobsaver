#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/WsXBRn

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
        c+=smoothrand(p+vec2(float(i)))*amp;
        
        p*=2.*vec2(( (i%2U == 0U)?(-1.):(1.) ),( (i%2U == 0U)?(1.):(-1.) ));
        a+=amp;
        amp/=2.;
    }
    return c / a;
}

//shape and animation parameters
float maxRadius = 1.;
float minRadius = 0.3;
float noiseLoopRadius = 3.;
float animationSpeed = .5;

float noiseLoop(vec2 uv, float t){
    float len = length(uv);
    float v = minRadius + noise((uv/len+vec2(t,0.))*noiseLoopRadius,10U)*(maxRadius-minRadius);
    return smoothstep(v-0.005,v,len);
}

void main(void)
{
    // Normalized pixel coordinates (from -1 to 1)
    vec2 uv = (2.*gl_FragCoord.xy-resolution.xy)/resolution.y;
    
    float t=time*animationSpeed;
    
    // Time varying pixel color
    vec3 col = 0.5 + 0.5*cos(t+uv.xyx+vec3(0,2,4));
    
    //vec2 bv = uv;
    //bv*=2./maxRadius;
    
    //float len = length(bv);
    //vec3 shape_col = vec3(noise(vec2(bv.x*bv.x*bv.y*bv.y,len-t),2U),noise(vec2(bv.x*bv.x*bv.y*bv.y+100.,len-t),2U),noise(vec2(bv.x*bv.x*bv.y*bv.y-100.,len-t),2U));
    
    col = mix(vec3(0.),col,noiseLoop(uv,t));
    //col = mix(shape_col,col,noiseLoop(uv/0.95,t));

    // Output to screen
    glFragColor = vec4(col,1.0);
}

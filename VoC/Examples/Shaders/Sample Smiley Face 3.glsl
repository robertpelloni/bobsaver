#version 420

// original https://www.shadertoy.com/view/XslcR2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define sat(x) clamp(x, 0., 1.)

vec4 createEyes(vec2 uv, vec2 mouse) {
    
    
    //vec4 col = vec4(0.95,0.98,0.98,1);
    vec4 irisCol = vec4(0.95,0.98,0.98,1);
    vec4 col = mix(vec4(1.), irisCol, smoothstep(.1, .15, length(uv))); 
    float d = length(uv-mouse*.2);                                    
    col.rgb = mix(col.rgb, vec3(.07, .45, .18), smoothstep(.07, .06, d));
    col.rgb = mix(col.rgb, vec3(.0), smoothstep(.04, .03, d));
    // iris outline
    
    /*vec2 lookAt;
    if(uv.x > 0.0) {
        lookAt = -1.0*mouse+loc;
    }
    else {
        lookAt = mouse+loc;
    }*/
    /*vec2 lookAt = mouse-loc;
    float num = length(loc)*100.0/10.0;
    if(length(lookAt) <.04){
        return vec4(0,0,0,1);
    }
    if(length(lookAt) <.07){
        return vec4(.08,.46,.05,1);
    }
    
     return mix(vec4(1,1,1,1), vec4(0.95,0.98,0.98,1), num);  */
    return col;

    
    
}

vec4 head(vec2 uv, vec2 mouse) {
 
    if( length(uv) < 0.4 ){
        if(length(uv) > 0.38) {
             
            return mix(vec4(0, 0, 0, 1), vec4(1.,1.,0.,1.), length(uv));
            
        }
        if(length(uv-vec2(.15, .09))<.15){
         
           return createEyes(uv-vec2(.15, .09), mouse);
        }
        if(length(uv-vec2(-.15, .09))<.15){
         
           return createEyes(uv-vec2(-.15, .09), mouse);
        }
        if(length(uv-vec2(0, -.1))<.2){
            if(uv.y < -.1) {
                return vec4(.93,.25,.25,1);
            }
        }
        
         return mix(vec4(1,1,0,1), vec4(.93,.79,.31,1), length(uv)*100.0/40.);
        
    }
    else {
        return vec4(0., 0., 0., 1.);
    }
    
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    uv -= 0.5;
    uv.x *= resolution.x/resolution.y;;
        
        
    vec2 mouse = mouse*resolution.xy.xy / resolution.xy;
    mouse -= .5;
    if(mouse.x <= -0.5){
        mouse = vec2(0,0);
    }
                     
    
    glFragColor = head(uv,mouse);
            
            
}

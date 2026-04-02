#version 420

// original https://www.shadertoy.com/view/tlXcR4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    
    vec2 luv;
    vec3 col;
    float p;
    glFragColor = vec4(0.6,0.8,0.9,1.0);
    
    for(float l = 10.0; l > 0.0; l -= 1.0){
 
        
        
        luv = vec2(fract( (l*uv.x+ time) *2.), l*uv.y);
        
        p = luv.y > l - 2.06
            ? smoothstep(.57,.55, distance(luv, vec2(.5,l-2.06)))
            : 1.;

       
        
        if (p>0.0){
            col = p*vec3(0.0,1.0-l/10.0,0.1);
            glFragColor = vec4(col,1.0);
        }

    
    }
    
}

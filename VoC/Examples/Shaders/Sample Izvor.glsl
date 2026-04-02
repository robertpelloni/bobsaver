#version 420

// original https://www.shadertoy.com/view/WsXfRn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 random2( vec2 p ) {
    return fract(sin(vec2(dot(p,vec2(127.1,311.7)),dot(p,vec2(269.5,183.3))))*43758.5453);
}

void main(void)
{
    
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv -= .5;
    uv.x *= resolution.x/resolution.y;
   
    
    
    //resize space
    uv *= 13.;
    
    vec2 st = vec2(atan(cos(uv.x*(1.-.2*cos(.6*time))), cos(uv.y*(1.-.2*cos(.6*time)))), length(uv));
    
    uv = vec2(st.x/6.2831*10. + 3.*sin(time), st.y*sin(.2*time - st.y*.1));
    
    //tile the space
    vec2 i_uv = floor(uv);
    vec2 f_uv = fract(uv);
    
    
    
    float minDist = 1.;
    
    for (int y = -1; y <= 1; y++)
        for (int x = -1; x <= 1; x++)  
        {
            vec2 neighbor = vec2(float(x), float(y));
            
            
            //random position from current + neighbor place in the grid
            vec2 point = random2(i_uv + neighbor);
            
            point = .5 + .5*sin(time + 6.2831*point);
            
            //vector between the pixel and the point
            vec2 diff = neighbor + point - f_uv;
            
            float dist = length(diff);
            
            minDist = min(minDist, dist);
        
         
        }
    
    vec3 color = 1.2*minDist*vec3(.85 + .2*uv.x, .7, .65 + .1*uv.y);
    
    //draw cell center
    color += .9 * smoothstep(.09, .01, minDist);
    //color += step(.98, f_uv.x) + step(.98, f_uv.y);
    
    
    glFragColor = vec4(color,1.0);
}

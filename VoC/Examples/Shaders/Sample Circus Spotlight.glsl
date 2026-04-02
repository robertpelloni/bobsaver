#version 420

// original https://www.shadertoy.com/view/WlySDm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv -= .5;
    uv.x *= resolution.x/resolution.y;
    
  
    vec2 st = uv;
    st.x -= sin(time)*.4;
    st.y -= cos(time*.3)*.23;
    float circle = 1.-smoothstep(.2,.284, length(st));
    float circleMask =smoothstep(.2,.284, length(st));
    uv.x *=1.3;
    
    uv.x += sin(uv.x+time)*.1+2.;
    uv.x += cos(uv.y+time*1.4)*.08+.3;
     
    float fr = fract(abs(uv.x*5.));
    float fr2 = 1.-fract(abs(uv.x*5.));
 
    float mask = fr*fr*fr2*4.-uv.y*.7;
    vec3 color = mix(vec3(uv.x*.4,.3,.2), vec3(1.,.5,.3), -uv.y);
    vec3 circleCol = circle*mix(vec3(1.,.8,0.), vec3(1.,1.,1.), circle);
    
    vec3 blueTint =vec3(.8,0.,1.)*(.6-mask)*.29;
    blueTint *= circleMask;
    
    vec3 yellowTint = mix(vec3(1.,.8,0.), vec3(1.,1.,0.), mask);
    yellowTint *= circle*.3;
    
    vec3 col = vec3(color*mask+blueTint+yellowTint);
    col += circleCol*.5;
  
    glFragColor = vec4(col,1.0);
}

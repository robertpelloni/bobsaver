#version 420

// original https://www.shadertoy.com/view/3scGWM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float rand(vec2 p)
{
    p = fract(p*vec2(234.51,124.89));
    p += dot(p,p+54.23);
    p = fract(p*vec2(234.51,124.89));
    p += dot(p,p+54.23);
    return fract(p.x);
}

float width = 0.2;

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    
    
    vec2 pos = 5.*vec2(sin(time*0.2)+0.1*time,cos(time*0.2)+0.1*time);
    vec3 col = vec3(0.);//0.5 + 0.5*cos(time+(gl_FragCoord.xy/resolution.xy).xyx+vec3(0,2,4));
    
    for(float i=5.;i<10.;i+=1.)
    {    
        vec2 uv = pos+((20.-1.8*i)*(gl_FragCoord.xy-.5*resolution.xy)/resolution.y);
        vec2 gv = (fract(uv)-0.5);
        vec2 id = floor(uv);
        vec3 col2 = (0.5 + 0.2*sin(time+(i/2.)+0.3*uv.xyx+vec3(0,2,4))*sin(time+(i/2.)+0.3*uv.xyx+vec3(0,2,4)) + 0.5*cos(time+(i/2.)+0.3*uv.xyx+vec3(0,2,4)))*(i+1.)/11.;

        gv.x *= (float(rand(id*i)>0.5)-0.5)*2.;

        float mask1 = smoothstep(-0.01,0.01,width-abs(gv.x+gv.y-0.5*sign(gv.x+gv.y+0.01)));
        float mask2 = smoothstep(-0.2,0.2,width-abs(gv.x+gv.y-0.5*sign(gv.x+gv.y+0.01)));

        // Output to screen
        col = - 0.3*mask2 + 0.5*(col2.r*col2.r+col2.g*col2.g+col2.b*col2.b + col2*col2)*col2*mask1 + col*(1.-mask1);
    }
    glFragColor = vec4(col,1.0);
}

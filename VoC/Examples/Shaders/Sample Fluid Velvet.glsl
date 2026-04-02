#version 420

// original https://www.shadertoy.com/view/wdjGzK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Fluid mixing effect based on shifted periodic functions
// weighted with asymptotically decreasing coefficients.
// Use the mouse to interact with the shader

//Parameters
#define SPEED 0.1

vec3 Effect(float speed, vec2 uv, float time)
{

    float t = time*speed;
    float rt = (t*0.45);
    float irt = (t*0.005);
    mat2 m1 = mat2(sin(rt),cos(rt),-cos(rt),sin(rt));
    vec2 uva=m1*uv;
    mat2 m2 = mat2(sin(irt),cos(irt),-cos(irt),sin(irt));
    for(int i=1;i<40;i+=1)
    {    
        float it = float(i);
        uva*=(m2);
        uva.y+=-1.0+(0.6/it) * cos(t + it*uva.x + 0.5*it)
            *float(mod(it,2.0)==0.0);
        uva.x+=1.0+(0.5/it) * cos(t + it*uva.y + 0.5*(it+5.0));
            // *float(mod(it,2.0)!=0.0);
      
        
    }
    //Intensity range from 0 to n;
    float n = 0.5;
    float r = n + n * sin(4.0*uva.x+t);
    float gb = n + n * sin(3.0*uva.y);
    return vec3(r,gb*0.8,gb);
}

void main(void)
{
    vec2 mouse = mouse*resolution.xy.xy/resolution.xy;
    mouse = 2.0 * mouse - 1.0;
    mouse.x *= resolution.x/resolution.y;
    
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv = 2.0 * uv - 1.0;
    uv.x *= resolution.x/resolution.y;
    
    
    float l = length(uv-mouse);
    //sigmoid fx
    uv *= abs(uv)/(abs(uv)+exp(-l*8.0));//*cos(uv);
    vec3 col = Effect(SPEED,uv,time);
    //col*= Effect(SPEED,uv,time+10.0);
    //col = float(l>=0.01) *col + 
       // float(l<0.01)*mix(vec3(0.0),col,l*8.0);
    glFragColor = vec4(col,1.0);
}

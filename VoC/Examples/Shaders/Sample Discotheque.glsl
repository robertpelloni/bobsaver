#version 420

// original https://www.shadertoy.com/view/mdlczs

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Discotheque by technochroma
// original "loonie" code by Crystalize, "gnarl" by jarble https://www.shadertoy.com/view/3syyDD

//loonie begin

vec2 loonie(vec2 z) {
    float r = dot(z,z);
    return r > 1. ? z : z * sqrt(1./r - 1.);
}

void main(void)
#define AA 7 
{
    vec2 uv = 1.0 * (gl_FragCoord.xy - 0.2*resolution.xy) / -resolution.y;
    
    float t = time;
    
    uv *= 1.5;
    uv = loonie(uv);
    uv -= vec2(t,t * 0.2 / 30.);
    uv *= 3.5;
    
//    float grid = mod(sin(uv.x)+cos(uv.y),2.);
    
     vec3 col;
     
// gnarls begin

    for(int c=0;c<5;c++){
//        vec2 uv = (gl_FragCoord.xy*20.0-resolution.xy)/resolution.y;
        t = time;
        for(int i=1;i<4;i++)
        {
            uv /= 1.00;
            uv += cosh(col.yx);
            uv += float(i) + (sin(uv.x)*atan(uv.y)+sin(uv.y)*sin(time)+cos(time)*sin(uv.x)); 
        }
     col[c] = (tan(sin(uv.x+uv.y+time)));
    }
    
    glFragColor = vec4(col,1.0);

// loonie end  
    
    // small bit of anti-aliasing (fixed 2)
    // drop this in voidmain after fragcolor
    
    vec2 of = vec2(0.3);

    #ifdef AA
    const float aa = float(AA);
    #else
    const float aa = 1.0;

    
    for(float i = 0.0; i < aa - 1.0; i++) {

        // super-sample around the center of the pixel.
        vec2 p = (-resolution.xy + 2.0*(uv + of))/resolution.y;
        col += render(p);
        of *= r(3.14159/8.0);
        
            }
    
    col /= aa;
    
    col += 0.2*clamp(col, 0.0, 0.5);
    col = pow(col, vec3(1.0/2.2));
        
    #endif 
    
    }
    

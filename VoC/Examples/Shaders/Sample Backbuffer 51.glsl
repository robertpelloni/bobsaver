#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;
uniform sampler2D backbuffer;

out vec4 glFragColor;

//fractal automata

#define fract(x) (x-floor(x))
#define PHI ((sqrt(5.)-1.)*.5)
#define TAU (8.*atan(1.))

vec3 hsv(float h,float s,float v)
{
    return mix(vec3(1.),clamp((abs(fract(h+vec3(3.,2.,1.)/3.)*6.-3.)-1.),0.,1.),s)*v;
}

mat2 rmat(float t)
{
    float c = sin(t);
    float s = cos(t);
    return mat2(c, s, -s, c);
}

void main()
{
        vec2 uv                = gl_FragCoord.xy/resolution;   
        vec2 aspect            = resolution/min(resolution.x, resolution.y);
     float scale        = 1.35;
        vec4 buffer             = texture2D(backbuffer, uv);
    scale            += dot(buffer.ywzx, .125*buffer.wzyx) * .25 * PHI;
    
        vec2 p                 = (uv-.5) * aspect * scale;
    vec2 m                 = (mouse-.5) * aspect * scale; 
    
        float dist        = length(m-p);

    float sum         = dot(buffer, vec4(1.,1.,1.,1.))*.25;
        mat2 rotation          = rmat((mouse.x-.5)*TAU)*PHI*sum;  
        

        vec2 st                = p * rotation;
    st             = abs(fract(st*aspect.yx*PHI)-.5);
    st            = abs(fract(st*1.25)*2.-.5);
    
        vec4 path            = texture2D(backbuffer, st); 

    float difference     = dot(buffer, path);
        
    vec3 color             = hsv(dist-sum*4., difference*.125, 1.05);

    
        glFragColor           = abs(normalize(buffer-path+vec4(color.xyz, PHI)));
    glFragColor.w        += 2./256.;
    
}//sphinx

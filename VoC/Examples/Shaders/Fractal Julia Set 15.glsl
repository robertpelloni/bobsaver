#version 420

// original https://www.shadertoy.com/view/fsG3Wy

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define R resolution
#define PI 3.14159265359
#define max_iter 512
#define AA 6

//#define time time
float rand(vec2 p)
{
    return (fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453)) * 1. ;
}

vec3 randCol(int i) {
    float f = float(i)/float(max_iter) * 2.0;
    f=f*f*2.;
    float t = time+1.;
    return vec3((sin(f*2.0)), (sin(f*4.)), abs(sin(f*8.0)));
}

vec3 julia(vec2 p, vec2 comp)
{
    float th = time*2.*PI/180.;
    mat2 rot = mat2(cos(th), -sin(th), sin(th), cos(th));
    vec3 col = vec3(0.0);
    vec2 z = (2.0*p - R.xy)/R.y;
    z *= rot;
    z *= 1.2;//pow(1.1, -time*0.7);//(fract(-time*0.05+0.99));
    vec2 c = comp; 
    float r = 20.;
    float iter = 0.0;
    vec3 jCol = vec3(0.0);
    vec2 zP;
    for (int i=0; i<max_iter; i++)
    {
        zP = z;
        z = vec2(z.x*z.x - z.y*z.y, 2.0*z.x*z.y) + c;
        vec2 temp = vec2(i);
        if (dot(z,zP)>r*r)
        {
            jCol = randCol(i*4);
            break;
        }
        
        iter += 1.0;
    }
    if (iter>float(max_iter)) return vec3(0.0);
    
    float d = length(z);
    float fIter = log2(log(d)/log(r));
    //iter -= fIter;
    float m = sqrt(iter/(float(max_iter)));
    float j = iter/float(max_iter);
    col = vec3( smoothstep(6.,.0,fIter) )*jCol*1.;
    return col + vec3(0.2);//jCol + (vec3(0.22,0.22,0.25)*(1.-j));
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (2.*gl_FragCoord.xy-R.xy)/R.y;
    
    vec3 accCol = vec3(0.);
    
    vec2 c1 =  vec2(-0.8 , 0.156);//vec2( -0.79, 0.141 );
    vec2 c2 =  vec2( -0.79, 0.141 );
    vec2 c4 =  vec2( -0.75, 0.16 );
    float a = 0.2*PI+sin(time*0.05)*0.5+0.5+3.;
    vec2 c3 = vec2(0.285,0.01);
    vec2 c = mix(c1,c2,sin(time*0.02+0.33));
    //c = mix(c2, c4,sin(time*0.05));
    
    
    for (int i=0; i<AA; i++)
    for (int j=0; j<AA; j++)
    {
        vec2 dx = -0.5 + vec2(float(i), float(j))/float(AA);
        accCol += julia(gl_FragCoord.xy + dx, c3);
    }
    accCol /= float(AA*AA);
    
    vec3 col = vec3(accCol);

    // Output to screen
    col = pow(col, vec3(2.2));
    glFragColor = vec4(col,1.0);
}

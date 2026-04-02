#version 420

// original https://www.shadertoy.com/view/4dK3Rz

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// increase max_iterations (up to 1000 or more) or AA (up to 5 or whatever) to improve quality
// or decrease them to improve performance

const int Nperiodic = 12;
const int max_iterations = 100;

#define  AA 2

vec2 pos = vec2(0.0);
vec3 totcol = vec3(0.0);
    
float izoom = 0.6;
vec2 ioffset = vec2( 2.55, 3.4);

void main(void)
{
    for( int jj=0; jj<AA; jj++ )
    for( int ii=0; ii<AA; ii++ )  
    {
        float X = 0.5;
    
        float templog = 0.0;    
        float lambda  = 0.0;
    
        pos = (((gl_FragCoord.xy + vec2(float(ii),float(jj))/float(AA)) / resolution.y) * izoom) + ioffset;
                    
        for (int i=0; i<max_iterations; i++ )     
        {    
            for(int j=0; j<6; j++) 
            {
                X = pos.x*X*(1.0 - X); 
                templog += log( abs( pos.x*(1.0 - 2.0*X)));
            }
            for(int j=0; j<6; j++) 
            {
                X = pos.y*X*(1.0 - X); 
                templog += log( abs( pos.y*(1.0 - 2.0*X)));
            }

        }     
        
        lambda = templog/float(max_iterations*Nperiodic);
    
        vec3 col = vec3 (0.0);
    
        if (lambda < 0.0) 
        {
            lambda = abs(lambda);
 
            lambda = clamp( lambda, 0.0, 1.0);     
            lambda = pow (lambda, 0.25);    
            col = vec3 (1.0, lambda, 0.0);
        }
        else
        {
            lambda = abs(lambda);
        
            lambda = clamp( lambda, 0.0, 1.0);     
            lambda = pow (lambda, 0.25);    
            col = vec3 (0.5, 0.5, lambda);
        }
        totcol += col;
    }
    totcol /= float(AA*AA);
    
    glFragColor = vec4 (totcol, 1.0);
}

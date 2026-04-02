#version 420

// original https://www.shadertoy.com/view/MtGSD1

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define AA 4
#define time time
#define ITER 256

#define csqr(z)  mat2(z,-z.y,z.x) * z 

float bailout = 1e2;

void main(void)
{
    vec3 col = vec3(0.0);
    for( int m=0; m<AA; m++ )
    for( int n=0; n<AA; n++ )
    {
        vec2 p = -1.0 + 2.0 * (gl_FragCoord.xy+vec2(float(m),float(n))/float(AA)) / resolution.xy;
        p.x *= resolution.x/resolution.y;
        bailout = bailout * 4.;
        float t = smoothstep(0.0,1.0,((-cos(time*.1+2.)+1.0)/2.0));
        
        float zoom = 1.0/(t*63.0+1.0);
        
        vec2 c = vec2(-p.y-0.5,p.x);
        c -= t*vec2(-2.94,4.1)*8.0;
        c *= zoom;
        vec2 z = vec2(0.0);
        int k=0;
        
        vec2 oldz1 = vec2(1);
        //vec2 oldz2 = vec2(1);
        float curv = 0.;
        
        for(int i=0; i<ITER; i++ )
        {
            z = c + csqr(z);
            vec2 tmp = vec2(1.,1.);
            if (i > 0)
            {
                //tmp = (z-oldz1)/(oldz1-oldz2);
                tmp = oldz1/z;
            }
            //tmp = z;
            //tmp = csqr(z);
            
            //curv = atan(tmp.y,tmp.x);
            //curv=(sin(2.*curv)+1.)*.5;
            
             curv = tmp.x*tmp.y/dot(tmp,tmp)+.5;
            
            //oldz2 = oldz1;
            oldz1 = z;
            
            if( dot(z,z)>bailout){k=i;break;}
        }
        
        if(dot(z,z)>bailout)
            col +=vec3(0.49,0.2,0.0)*(float(k)/50.0)+vec3(0.0,curv,1.-2.5*curv)*0.9;
    }
    col /= float(AA*AA);
    glFragColor = vec4( col, 1.0 );
}

#version 420

// original https://www.shadertoy.com/view/XtKSDz

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define AA 3
#define time time

void main(void)
{
    vec3 col = vec3(0.0);
    for( int m=0; m<AA; m++ )
    for( int n=0; n<AA; n++ )
    {
        vec2 p = -1.0 + 2.0 * (gl_FragCoord.xy+vec2(float(m),float(n))/float(AA)) / resolution.xy;
        p.x *= resolution.x/resolution.y;
        
        float t = smoothstep(0.0,1.0,((-cos(time*.1)+1.0)/2.0));
        
        float zoom = 1.0/(t*63.0+1.0);
        
        vec2 c = vec2(-p.y-0.5,p.x);
        c -= t*vec2(-2.94,4.1)*8.0;
        c *= zoom;
        vec2 z = vec2(0.0);
        vec2 w = c;
        int k=0;
        for(int i=0; i<60; i++ )
        {
            z = c + vec2( z.x*z.x - z.y*z.y, 2.0*z.x*z.y );
            w = 0.985*w+0.015*vec2( z.x*z.x - z.y*z.y, 2.0*z.x*z.y )/dot(z,z);
            if( dot(z,z)>1024.0 ){k=i;break;}
        }
        
        if(dot(z,z)>1024.0)
            col +=vec3(0.9,0.0,0.0)*(float(k)/50.0)+vec3(0.0,w.x,abs(w.y))*0.9;
    }
    col /= float(AA*AA);
    glFragColor = vec4( col, 1.0 );
}

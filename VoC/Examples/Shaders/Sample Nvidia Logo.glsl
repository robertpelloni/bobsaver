#version 420

// original https://www.shadertoy.com/view/4tVXDK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/**/ // nVidia logo as parabols // see https://www.desmos.com/calculator/5zxv6ozlxa

void main(void)
{
    vec2 O=vec2(0.0);
    vec2 U = (gl_FragCoord.xy+gl_FragCoord.xy -(O.xy=resolution.xy)) / O.y *3.;
    U.y -= .2;
    
    float A=5., B=5.7, // top vs bottom stretching
          x2 = .06*U.x*U.x,
           y = abs(U.y),
           l = (A-y) / (1.+x2); // inversing  y = A -k* ( 1+x2 ) -> k=... -> draw isoval
    if (U.y<0.) {               // inversing -y = B -k*( 1+x2*(B-k)/(A-k)) ) (matching at y=0)
        float a = -1.-x2,       //            implies solve a 2nd degree polynomial :-(
              b = A+B + B*x2-y,
              c = -A*(B-y);
              l = ( -b +sqrt(b*b-4.*a*c) ) / (2.*a);
        if (U.x>0.) {           // bottom right cadrant is special
            l = (B-y) / (1.+x2/1.55);
            if (l>5.) l=0.;                      // spiral interior end
            if (U.y > (a=max(U.x-2., 1.3*(1.37-U.x)))) l = 3.-(a-U.y);
            if (U.x>3.5 && U. y> 1.-.45*U.x) l=0.; // spiral exterior end
        }
      }   
 
    l = clamp( 4.*sin(6.28*max(3.,l)) , 0.,1.);
    glFragColor = mix(vec4(1), vec4(.5,.72,.1,1), U.x<-.3 ? l : 1.-l );

}

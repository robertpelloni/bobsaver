#version 420

// original https://www.shadertoy.com/view/llSSDV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float iter    = 64.,
            divAng  = 24. * 6.2831853/360.,
            circRad = .23, 
            rat     = .045/circRad;

float nearestMult(float v, float of) {
    float m = mod(v, of);
    v -= m * sign(of/2. - m);
    return v - mod(v,of);
}

//Color palette function taken from iq's shader @ https://www.shadertoy.com/view/ll2GD3
#define  pal(t) ( .5 + .5* cos( 6.283*( t + vec4(0,1,2,0)/3.) ) )

void main(void) {
    vec2 R = resolution.xy,
         center = vec2(0.), p;
    
    float time = time,
          sCircRad = circRad*rat, 
          ds = (3.2+ 1.3*abs(sin(time/10.))) * rat,
          ang, dist,
          M = max(R.x, R.y);
    
     vec2 uv2 = ( gl_FragCoord.xy -.5*R) / M / .9;
    
    for(float i=0.;i< iter;i+=1.) {
        p = uv2-center;
        ang =  atan(p.y,p.x);        
        ang = nearestMult(ang, divAng);     
        center += sCircRad/rat* vec2(cos(ang), sin(ang));
        dist = distance( center, uv2);

        vec4 outcol = glFragColor;   
        if( dist <=sCircRad )
             outcol += 15.*dist * pal( fract(dist/sCircRad + abs(sin(time/2.))) );
          sCircRad *= ds;
        glFragColor = outcol;
    }
}

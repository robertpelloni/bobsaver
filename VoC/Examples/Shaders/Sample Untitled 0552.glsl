#version 420

// original https://www.shadertoy.com/view/Ws2cW1

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float sdBox( in vec2 p, in vec2 b )
{
    vec2 d = abs(p)-b;
    return length(max(d,0.0)) + min(max(d.x,d.y),0.0);
}

float sdRoundBox( vec3 p, vec3 b, float r )
{
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0) - r;
}

// from https://necessarydisorder.wordpress.com/
float ease(float p, float g) {
    if(p < 0.){
        return 0.;
    } else if(p > 1.){
        return 1.;
    } else {
        if (p < 0.5) 
            return 0.5 * pow(2.*p, g);
        else
            return 1. - 0.5 * pow(2.*(1. - p), g);
    }
}

float smin( float d1, float d2, float k ) {
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h); }

float smax( float d1, float d2, float k ) {
    float h = clamp( 0.5 - 0.5*(d2+d1)/k, 0.0, 1.0 );
    return mix( d2, -d1, h ) + k*h*(1.0-h); }

float smaxi( float d1, float d2, float k ) {
    float h = clamp( 0.5 - 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) + k*h*(1.0-h); }

void main(void)
{
    vec2 p = (gl_FragCoord.xy - 0.5*resolution.xy)/resolution.y;
    vec3 col = vec3(0);
    
#define time mod(time, 2.37)

    float d = 10e7;
    
    float range = 1.;
    
    float w = 20.5;
    
    p.x -= w*1.;
    float sdPl = sdBox( p, vec2(w,2.));
    
    p.x += w*1.;
    vec2 bp = vec2(0);
    
    float ea = ease(time,3.);
    float eb = ease(time- 1.,3.);
    
    float ec = ease((time- 2.)*2./0.65,1.);
    
    bp.x -= range*0.5;
    bp.x += ea;
    bp.x -= eb;
    
    float sz = 0.15;
    
    float sdB = length(p - bp) - sz;
    
 
    float amt = 0.4;
    
    d = min(d, sdPl);
    //d = min(d, length(p - bp) - 0.1);
    
    
    //col += smoothstep(0.,0.001,-d);
    
    
    d = mix(
        d = smin(d, sdB, amt),
        d = smaxi(d, -sdB, amt),
        ea
    );
    
    if(time > 2.){
    
        bp -= bp;
        bp.x -= range/2.*ec;
        d = sdPl;
        //sdB = length(p - bp) - ec*0.4+ (0.)*(1. - pow(ec, 0.2));
        sdB = length(p - bp) - ec*sz+ (sz)*(1. - pow(ec, 0.6));
        //d = smin(d, sdB, ec*1.*amt);
        d = smin(d, sdB, 1.*amt);
        
        
    }
    
    
    
    
    //d = min(d, sdPl);
    
    //d = min(d, smaxi(sdPl, -sdPl, 0.4));
    //d = max(d, -smaxi(sdB, sdPl, amt*0.3));
    
    //d = smin(d, min(length(p - bp) - 0.1, -sdPl), 0.3);
    
    
    //d = min(d, -sdPl);
    
    col += smoothstep(0.,0.004,-d);

    glFragColor = vec4(col,1.0);
}

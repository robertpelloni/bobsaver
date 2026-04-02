#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

mat2 rot( float a ){ return mat2( sin(a),  cos(a), -cos(a),  sin(a) ); }

float noise( in vec2 x ){ return smoothstep(0.,1.,sin(1.5*x.x)*sin(1.5*x.y)); }

float fbm( vec2 p )
{
    mat2 m = rot(.4);
    float f = 0.0;
    f += 0.500000*(0.5+0.5*noise( p )); p = m*p*2.02;
    f += 0.250000*(0.5+0.5*noise( p )); p = m*p*2.03;
    f += 0.125000*(0.5+0.5*noise( p )); p = m*p*2.01;
    f += 0.062500*(0.5+0.5*noise( p )); p = m*p*2.04;
    f += 0.031250*(0.5+0.5*noise( p )); p = m*p*2.01;
    f += 0.015625*(0.5+0.5*noise( p ));
    return f/0.96875;
}

float pattern (in vec2 p, out vec2 q, out vec2 r, float t){
   
    
    q.x = fbm( p + vec2(0.0,0.0) + .7*t );
    q.y = fbm( p + vec2(5.2,1.3) + 1.*t );

    r.x = fbm( p + 10.0*q + vec2(1.7,9.2) + sin(t) );
    r.y = fbm( p + 12.0*q + vec2(8.3,2.8) + cos(t) );

    return fbm( p + 3.0*r );
    
}

void main(void) { //WARNING - variables void (out vec4 C, in vec2 U){ need changing to glFragColor and gl_FragCoord
    vec4 C = glFragColor;
    vec2 U = gl_FragCoord.xy;
    
    vec2 uv = (U.xy - mouse*resolution.xy.xy)/resolution.xy * 2.;
    uv.x *= resolution.x/resolution.y;
    
    vec2 q,r;
    vec3 col1 = vec3(0.,.9,.8);
    vec3 col2 = vec3(1.,.6,.5);
    vec3 c;
    
    float f = pattern(uv, q, r, 0.1*time);
       vec2 df = vec2(dFdx(f) , dFdy(f));
    
    c = mix(col1, vec3(0), smoothstep(.0,.8,f));
    //c = mix(col2, c, smoothstep(0., .8, dot(q,r)));
    c += col2 * smoothstep(0., .8, dot(q,r)*0.6);
    //c *= dot(q,r);
    //c += smoothstep(0.,3.,pow(length(df),0.12));
    

    C = vec4( c, 1. );

    glFragColor = C;
}

#version 420

// original https://www.shadertoy.com/view/lssfW2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Playing with parametric curve
vec2 m,n;

vec2 map(float t){//from iq's shader https://www.shadertoy.com/view/Xlf3zl
    return 0.85*cos( (t+n) + vec2(0.0,1.0) )*(0.6+0.4*cos(t*(7.0)+m+vec2(0.0,1.0)));
}

void main(void) {
    vec2 p=(2.0*gl_FragCoord.xy-resolution.xy)/resolution.y;
    
    // Curve animation
    m = cos( 0.42*time + vec2(2.0,0.0) );
    n = cos( 0.61*time + vec2(3.0,1.0) );
    
    // Evaluate distance to the parametric function
    float t=0.0,d=length(p-map(t)),dt=0.001,d1=d;
    for(int i=0;i<150;i++){
        t+=0.2*d1;
        d1=length(p-map(t));
        d=min(d,d1);
    }
    
    
    //d=smoothstep(0.0,0.01,d);   
    vec3 col=vec3(sqrt(d),d*d,d);    
    float dn = col.x + col.y + col.z;
    col /= dn;
        
    glFragColor = vec4(col,1.0);
}

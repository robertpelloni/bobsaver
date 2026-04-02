#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main( void ) {

    float cm=0.35;
    vec2 position = (( gl_FragCoord.xy -  resolution.xy*.5 ) / resolution.x )+vec2(0,-cm);

    
    
    // 256 angle steps
    float angle = atan(position.y,position.x)/(2.*3.14159265359);

    angle += floor(angle)+time*0.02;
    
    float rad = length(position);
    
    float color = 0.0;
    for (int i = 0; i < 25; i++) {
        float angleFract = fract(angle*256.);
        float angleRnd = floor(angle*256.)+123423.;
        float angleRnd1 = fract(angleRnd*fract(angleRnd*.7235)*45.1);
        float angleRnd2 = fract(angleRnd*fract(angleRnd*.82657)*13.724);
        float t = time+angleRnd1*10.;
        float radDist = sqrt(angleRnd2+float(i));
        
        float adist = radDist/rad*.1;
        float dist = (t*.1+adist);
        dist = abs(fract(dist)-.5);
        
        float mp=.25;
        
        color += max(0.,mp-dist*50./adist)*(mp-abs(angleFract-mp))*25./adist/radDist;
        
        angle = fract(angle+.61);
        
    }

    
    glFragColor = vec4( color )*(.2+cm);

}

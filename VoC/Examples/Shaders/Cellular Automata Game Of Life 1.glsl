#version 420

// Conway's game of life

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;
uniform sampler2D backbuffer;

out vec4 glFragColor;

vec4 live = vec4(1.,1.,1.,1.);
vec4 dead = vec4(0.,0.,0.,1.);

void main( void ) {
    vec2 position = (gl_FragCoord.xy/resolution.xy);
    float pw = 1.0/resolution.x; //pixel width
    float ph = 1.0/resolution.y; //pixel height
    

    if (length(position-mouse) < 0.01) {
        //random circle of pixels at mouse position
        float rnd1 = mod(fract(sin(dot(position + time * 0.001, vec2(14.9898,78.233))) * 43758.5453), 1.0);
        if (rnd1 > 0.5) {
            glFragColor = live;
        } else {
            glFragColor = dead;
        }
        
    } else {
        //add up live white neighbor pixels
        int count = 0;
        
        vec4 C = texture2D( backbuffer, position );
        vec4 E = texture2D( backbuffer, vec2(position.x + pw, position.y) );
        vec4 N = texture2D( backbuffer, vec2(position.x, position.y + ph) );
        vec4 W = texture2D( backbuffer, vec2(position.x - pw, position.y) );
        vec4 S = texture2D( backbuffer, vec2(position.x, position.y - ph) );
        vec4 NE = texture2D( backbuffer, vec2(position.x + pw, position.y + ph) );
        vec4 NW = texture2D( backbuffer, vec2(position.x - pw, position.y + ph) );
        vec4 SE = texture2D( backbuffer, vec2(position.x + pw, position.y - ph) );
        vec4 SW = texture2D( backbuffer, vec2(position.x - pw, position.y - ph) );
        
        if (E.r == 1.0) { count++; }
        if (N.r == 1.0) { count++; }
        if (W.r == 1.0) { count++; }
        if (S.r == 1.0) { count++; }
        if (NE.r == 1.0) { count++; }
        if (NW.r == 1.0) { count++; }
        if (SE.r == 1.0) { count++; }
        if (SW.r == 1.0) { count++; }
        
        //follow the game of life update rules
        if ( (C.r == 0.0 && count == 3) || (C.r == 1.0 && (count == 2 || count == 3))) {
            glFragColor = live;
        } else {
            //glFragColor = vec4(1.0/count,1.0/count,1.0/count,1.0);
            glFragColor = dead;
        }
    }
}

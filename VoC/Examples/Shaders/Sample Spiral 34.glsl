#version 420

// original https://www.shadertoy.com/view/3sfBW4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float drawspiral(in float wingsize, float fuzz, float d, float offset, float wings, float zoom, float speed, float nudge){
    //Draw displacement map
    return smoothstep(wingsize, wingsize+fuzz,
                      abs(sin(d*zoom+
                              offset*wings+
                              time*speed+
                              nudge)));
}

void main(void) {
    vec2 st = gl_FragCoord.xy/resolution.xy;
    vec3 color = vec3(0.0);
    float d = 0.0;
    
    //Place origin at center of screen
    st = st *2.00-1.000;
    st.x *= resolution.x/resolution.y;
    
    //Concentric circles distance map from center
    d = length( abs(st) );
    
    //Nudge pixels towards the center relative to the angle from the X axis
    float offset = (atan(st.y/st.x));  
    
    //Unfocus edgest more when closer to center
    float focus = pow(d,-.5)/2.00;
    
    // Edit these things for fun and profit
    //                     (size , fuzz       , d, offset, wings, zoom , speed, nudge)
    float r = drawspiral(0.700, 0.50*focus, d, offset, 6.000, 20.*sin(time/3.0 -1.57078), 1.000, 1.800);
    float g = drawspiral(0.700, 0.50*focus, d, offset, 6.000, 20.*sin(time/3.0 ), 1.000, 2.000);
    float b = drawspiral(0.700, 0.50*focus, d, offset, 6.000, 20.*sin(time/3.0 +1.57078), 1.000, 2.200);
        
    glFragColor = vec4(r, g, b, 1);
    
    //uncomment this line to force black and white and read only from 'b' only
    //glFragColor = vec4(vec3(b), 1);

}

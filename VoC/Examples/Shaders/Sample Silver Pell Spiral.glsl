#version 420

// original https://www.shadertoy.com/view/3t2yWW

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// How can I make this zoom nicely?
// The zoom is currently... number-crunched

// https://www.shadertoy.com/view/wljyWh       - I learned about this from this shader
// https://en.wikipedia.org/wiki/Silver_ratio  - Wikipedia page
// https://www.youtube.com/watch?v=7lRgeTmxnlg - Numberphile video  

#define ratio 1./(1. + sqrt(2.))

float sdBox(vec2 p, float s){
    p = abs(p) - s;
    return max(p.y, p.x);
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - 0.5*resolution.xy)/resolution.y;

    vec3 col = vec3(0);
    
    
    float d = 10e6;
    
    uv /= pow(2.,mod(time,  2.543106606327)); // this line thanks to Fabrice! 
    
    uv.x += sqrt(2.);
    
    

    
    float s = 1.;
    
    
        
    
    float iters = 9.;
    
    vec2 p = uv;
    
    for(float i = 0.; i < 2.; i++){
        if (i == 0.){
            // left spiral
            float firstBox = sdBox(uv, s);
            d = min(d,abs(firstBox));
            d = min(d,abs(max(length(uv - vec2(s,-s)) - s*2., firstBox)));
        }
        if (i == 1.){
            // right spiral
            p = uv; s = 1.;

            p.x -= s*2. + s * ratio*2.;

            p.x = - p.x;
            p.y = - p.y;

            float firstBox = sdBox(p, s);
            d = min(d,abs(firstBox));
            d = min(d,abs(max(length(p - vec2(s,-s)) - s*2., firstBox)));        
        }
        
        
        
        for(float j = 0.; j < iters; j++){

            float dSpiral;
            if ( mod(j, 4.) == 0. ){
                p.xy -= vec2(s,s);
                s *= ratio;
                p.xy -= vec2(s,-s);

                dSpiral = length(p - vec2(-s,-s)) - s*2.;
            } else if ( mod(j, 4.) == 1. ){
                p.xy -= vec2(s,-s);
                s *= ratio;
                p.xy -= vec2(-s,-s);

                dSpiral = length(p - vec2(-s,s)) - s*2.;
            } else if ( mod(j, 4.) == 2. ){

                p.xy -= vec2(-s,-s);
                s *= ratio;
                p.xy -= vec2(-s,s);

                dSpiral = length(p - vec2(s,s)) - s*2.;
            } else if ( mod(j, 4.) == 3. ){

                p.xy -= vec2(-s,s);
                s *= ratio;
                p.xy -= vec2(s,s);

                dSpiral = length(p - vec2(s,-s)) - s*2.;
            }

            float dBox = sdBox(p, s);

            d = min(d,
                    ( min( abs(dBox), max( dSpiral, dBox)))
                   );
        }
    }
    
    
    
    col = mix(col,vec3(1),smoothstep(dFdx(uv.x),0.,abs(d)));
    
    col = pow(col,vec3(0.4545)); // gamma correction
    
    glFragColor = vec4(col,1.0);
}

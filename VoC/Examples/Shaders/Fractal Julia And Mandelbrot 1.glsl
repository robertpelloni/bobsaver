#version 420

// original https://www.shadertoy.com/view/XldcRM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float BREAK =50000.;
const int ITER = 100;
const int repeat = 5; //ADJUST THIS FOR PERFORMANCE
const float boxSize = 2.0; 

const int MANDLE_BROT_BACKGROUND = 1;

const vec3 hitCol =  vec3(.4,.4,.8);

vec3 julia(vec2 pos , vec2 c){
       vec2 hold;
    int i = 0;
    float smoothcolor = exp(-length(pos));
    for(; i < ITER; i++) { 
        hold.x = pos.x*pos.x-pos.y*pos.y;
        hold.y = 2.0*pos.x*pos.y;
        pos = hold+c;
        smoothcolor += exp(-length(pos));
        if(length(pos) > BREAK) {
            return vec3(1,0,.99)*pow(min(1.,smoothcolor/float(ITER)*1.),.2);
        }
    }
    return hitCol;

}

void main(void)
{
    vec2 m = vec2( -.743,.131);
    
    // Normalized pixel coordinates (from 0 to 1)
vec2 uv = boxSize*(gl_FragCoord.xy-resolution.xy*0.5)/resolution.y;
m = boxSize*(mouse*resolution.xy.xy-resolution.xy*0.5)/resolution.y;
    vec2 pixSize = boxSize/resolution.xy;
    // Time varying pixel color
    
    vec3 dark = vec3(0.,0,0);
    for(int i = 0; i < repeat; i++) { 
        for(int j = 0; j < repeat; j++) { 
            dark+=julia(uv+vec2(i,j)*pixSize/float(repeat),m);
        }
    }
    dark = dark/float(repeat*repeat);
    vec3 mand = julia(uv,uv);
    if (mand!=hitCol){
        mand *= 0.;
    }
    vec3 col = float(MANDLE_BROT_BACKGROUND)*mand*vec3(0,1,1)*.3+.9*dark*vec3(1,1,1)+pow(length(m.xyx-uv.xyx),-3.)/300000.;

    // Output to screen
    glFragColor = vec4(col,1.0);
}

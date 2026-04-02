#version 420

// original https://www.shadertoy.com/view/3tycWV

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Fork of "Day 405" by jeyko. https://shadertoy.com/view/ttVcRt
// 2021-01-27 11:17:18

const float slices = 350.;

const float aaSteps = 1.; // not really steps, it's the exponentially ^3 area growing area around the gl_FragCoord.xy 

const float disp = .7;

const float width = 0.0004;

// asin(sin) is a triangle wave
#define sin(x) asin(sin(x))

float fun(float p, float py){
    
    //float f = sin(p + time + cos(py*0.05 + sin(p))*0.7)*sin(py*0.1 + time*0.2);
    py *= 170.;
    
    py += time*2.;
    float f = abs(sin(p*9. + sin(py*0.2 )*1.));
    
    f = pow(max(f,0.001),0.15);
    
    //f += (sin(py*0.1 + time + sin(p*6. + time)))*0.1;
    f += (sin(py*0.1 + time + sin(p*8. + time*.1 + sin(py*2.)*0.1)))*0.1;
    
    
    
    //f = cos(p*0.4- time + py)*cos(p*0.4*sin(p) + time)*(sin(py + time));
    //f = sin(p*0.5 + sin(py))*(cos(py*0.1 + time));
    /*
    f *= mix(
        smoothstep(0.,1.,abs(p + sin(py)*0.1)),
        smoothstep(0.,1.,abs(p + sin(py*0.3 + time)*0.1)),
        0.5 + sin(time*0.4 )*0.5
        );
    */
    return f*disp;
}

const float eps = 0.0004; // eps for derivative of graphing function

float graph(float y, float fn0, float fn1, float pixelSize){
  return smoothstep(pixelSize ,0., 
                    abs(fn0-y)/length(vec2((fn1-fn0)/eps,1.))- width);
}
float graphNoAbs(float y, float fn0, float fn1, float pixelSize){
  return smoothstep(pixelSize,0., 
                    -(fn0-y)/length(vec2((fn1-fn0)/eps,1.)) - width);
}

vec3 get(vec2 FragCoord){
    vec2 uv = (FragCoord.xy - 0.5*resolution.xy)/resolution.y;
    
    vec3 col = vec3(0);

    
    float pixelSize = dFdx(uv.x);
    
    for(float i = 0.; i < slices; i++ ){
        vec2 p = uv + vec2(0.,i/slices*2. - 0.6);
        
        //float funIdx = p.x*4. + sin(p.y*i/slices*2. + time)*1.5*sin(p.x - time);
        float funIdx = p.x;
        float funIdxY = i/slices;
        
        col -= graphNoAbs( p.y, fun(funIdx,funIdxY), fun(funIdx+eps,funIdxY), pixelSize);
        col = max(col,0.);
        col = mix(col, vec3(1), graph( p.y, fun(funIdx,funIdxY), fun(funIdx+eps,funIdxY ), pixelSize ));
        
    }
    
    
    col = 1. - col;
    return col;
}

void main(void)
{
    vec3 col = vec3(0);
    
    
    for(float i =0.; i < aaSteps*aaSteps + min(float(frames),0.)   ; i++){
        col += get(gl_FragCoord.xy + vec2(mod(i,aaSteps),floor(i/aaSteps))/aaSteps);
    }
    col /= aaSteps*aaSteps;
    
    
    col = max(col, 0.);
    //col = pow(col, vec3(0.4545));
    
    
    col = pow(col,vec3(0.4545));
    
    glFragColor = vec4(col,1.0);
}

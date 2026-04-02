#version 420

// original https://www.shadertoy.com/view/ttVcRt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define slices 180.

const float disp = 0.4;

const float eps = 0.01;

const float width = 0.00035;

float fun(float p, float py){
    
    float f = sin(p + time + cos(py*0.05 + sin(p))*0.7)*sin(py*0.1 + time*0.2);
    
    //f = cos(p*0.4- time + py)*cos(p*0.4*sin(p) + time)*(sin(py + time));
    //f = sin(p*0.5 + sin(py))*(cos(py*0.1 + time));
    
    f *= mix(
        smoothstep(0.,1.,abs(p + sin(py)*0.1)),
        smoothstep(0.,1.,abs(p + sin(py*0.3 + time)*0.1)),
        0.5 + sin(time*0.4 )*0.5
        );
    
    return f*disp;
}

float graph(float y, float fn0, float fn1, float pixelSize){
  return smoothstep(pixelSize ,0., 
                    abs(fn0-y)/length(vec2((fn1-fn0)/eps,1.))- width);
}
float graphNoAbs(float y, float fn0, float fn1, float pixelSize){
  return smoothstep(pixelSize,0., 
                    -(fn0-y)/length(vec2((fn1-fn0)/eps,1.)) - width);
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - 0.5*resolution.xy)/resolution.y;
    
    vec3 col = vec3(0);

    
    float pixelSize = dFdx(uv.x)*1.25;
    
    for(float i = 0.; i < slices; i++ ){
        vec2 p = uv + vec2(0.,i/slices*2. - 0.8);
        
        //float funIdx = p.x*4. + sin(p.y*i/slices*2. + time)*1.5*sin(p.x - time);
        float funIdx = p.x;
        
        col -= graphNoAbs( p.y + 0.0, fun(funIdx,i), fun(funIdx+eps,i), pixelSize);
        col = max(col,0.);
        col = mix(col, vec3(1), graph( p.y, fun(funIdx,i), fun(funIdx+eps,i), pixelSize ));
        
    }
    
    
    col = 1. - col;
    
    
    col = pow(col,vec3(0.4545));
    glFragColor = vec4(col,1.0);
}

#version 420

// original https://www.shadertoy.com/view/wlfXRn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

mat2 rot(float a)
{
 return mat2(cos(a), -sin(a), sin(a), cos(a));   
}

float rnd(vec2 p)
{
 return fract(sin(dot(p, vec2(12.9898, 78.233)))*43753.225432);   
}

float flower(vec2 p, float size, float leafTh, float leafNum)
{
    //size depends on the leafTh somehow
    //size = *2.;
    vec2 st = p*rot(-sin(time));
    p = p*rot(time/2.);
    
    st = st*size;
    p = p*size;
    
    float c = 1.0-step(0.3, length(p));
    float c2 = 1.0-step(0.5, length(p));
    float a = atan(p.y, p.x);
    float a1 = atan(st.y, st.x);
    
    //leafNum ex. 3. leafTh ex. 1.4
    float leafs = abs(cos(a*leafNum ))+leafTh;
    
    float leafs2 = abs(cos(a1*leafNum ))+leafTh;
    float leafs3 = abs(cos(a*leafNum))+leafTh;
    
    float fl = 1.-step(leafs, length(p));
    float f2 = 1.-step(leafs2, length(p)*1.7);
    
    float f3 = 1.-step(leafs3, length(p)*4.);
 return fl+c+f2*2.+f3*3.-leafs/6.;//+leafs3/2.;   
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    vec2 qt = uv;
    qt *=  1.0 - qt.yx;
    float vig = qt.x*qt.y*15.;
    vig = pow(vig, 0.05);
    
    uv.x*=resolution.x/resolution.y;
    
    vec2 index = floor(uv*6.);
    vec2 st = fract(uv*6.);
    st = st*2.0-1.0;
    float seed = rnd(index);

    // Time varying pixel color
    float f = max(0.0, flower(st, 4.+seed*2.4, 1.5+seed*4.5, 2.+seed*8.));
    float solidF = smoothstep(0.0, 0.05, f);
    
    vec3 col = vec3(0.8)*vig;
    
    col = mix(col, vec3(1., 0.1+seed,0.05+seed)*(f+0.3),  solidF);
    col = mix(col, vec3(1.), step(1.5, f));
    col = mix(col, vec3(213., 123., 15.)/255., step(3.5, f));
    // Output to screen
    glFragColor = vec4(col,1.0);
}

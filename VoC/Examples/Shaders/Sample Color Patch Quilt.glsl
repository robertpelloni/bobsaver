#version 420

// original https://www.shadertoy.com/view/ssXcR7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float Hash21(vec2 p){
    p = fract(p*vec2(234.34, 435.345));
    p += dot(p, p+34.23);
    return fract(p.x*p.y);
}

float[14] Hash21List(vec2 p){
    float[14] res;
    
    float x = 0.;
    for(int i = 0; i<12; i++){
        x = Hash21(p+x);
        res[i] = x;
    }
    
    return(res);
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    // vec2 uv = gl_FragCoord.xy/resolution.xy;
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    
    uv.x += sin(time*.3);
    uv.y += time*.3;
    uv *= 5.5;
    
    vec2 gv = fract(uv);
    
    vec2 id = floor(uv);
    
    vec4 col = vec4(0);
    
    //
    
    float[] rl = Hash21List(id);
   
    float x0 = 0.;
    float x1 = 0.33*rl[0];
    float x2 = 0.33+0.33*rl[1];
    float x3 = 1.;
    
    if( gv.x >=x0 && gv.x <= x1 ) col = vec4(rl[2],rl[3],rl[4],rl[5]);
    if( gv.x >=x1 && gv.x <= x2 ) col = vec4(rl[6],rl[7],rl[8],rl[9]);
    if( gv.x >=x2 && gv.x <= x3 ) col = vec4(rl[10],rl[11],rl[12],rl[13]);
    
    
    
    // if( gv.x>=0.99 || gv.y>=0.9) col = vec3(1,1,1);
    //col.rg = gv;
    
    //if(uv.x>=.99 || uv.y>=.99) col = vec3(1,0,0);
    
    // Output to screen
    glFragColor = col;
}

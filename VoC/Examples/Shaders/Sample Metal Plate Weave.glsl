#version 420

// original https://www.shadertoy.com/view/3t23WK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float circle(vec2 p, float r)
{
 float ss= 0.009;
    float c = length(p);
    float circ1 = 1.0-smoothstep(r-ss, r+ss, c);
    float circ2 = 1.0-smoothstep(r-ss-0.3, r+ss-0.3, c);
    
    
    //all the hacks!
    float stripes =  pow(abs(max(0.,sin(c*35.)))/2., 0.7);//mod(floor(c*8.), 2.)/1.5;
    float fullC = circ1-circ1*(stripes+1.6)/4.; //0 to 1 minues 0.25 to .0.50
    return clamp(fullC-abs(sin(atan(p.y, p.x)*1.+time/2.))/3., .0, 1.);
}

float circle2(vec2 p, float r)
{
 float ss= 0.009;
    float c = length(p);
    float circ1 = 1.0-smoothstep(r-ss, r+ss, c);
    return circ1;
}
void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv.x*=resolution.x/resolution.y;
    uv+=time/8.;
    vec2 st = uv;
    uv = fract(uv*2.);
    uv = uv*2.0-1.0;
    

    // Time varying pixel color
    vec3 col =vec3(0.);
    vec3 red = vec3(0.6, 0., 0.);
    vec3 blue = vec3(213., 123., 15.)/305.;
    vec3 green = vec3(0.3, 0., 0.);
    vec3 yellow = vec3(213., 163., 15.)/255.;
 
    
    
    
    
    //This is my favourite line in the whole thing!!!
    uv = abs(uv)*2.-1.;
    
    
    
    
    
    
    //the circles
    float c1 =  circle(uv+1., 1.25);
    float c2 = circle(uv+vec2(-1., 1.), 1.25);
    float c3 = circle(uv-1., 1.25);                //subtract by just a pure circle
    float c4 = circle(uv+vec2(1., -1.), 1.25)-circle2(uv+1., 1.25);
   // c4 = clamp(c4, 0.0 ,1.);
        
           col = mix(col, red*c1, smoothstep(0.1, 0.101,c1));
        //col = mix(col, blue, c1/5.);
        col = mix(col, blue*c2, smoothstep(0.1, 0.101,c2));
        col = mix(col, green*c3, smoothstep(0.1, 0.101,c3)); 
        col = mix(col, yellow*c4, smoothstep(0.1, 0.101,c4));
    

    st = uv;
    float border = 1.0-(step(0.9, st.x)+step(0.9, st.y));

        
    // Output to screen
    glFragColor = vec4(col*step(uv.x,1.)*2.5,1.0);
}

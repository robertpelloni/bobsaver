#version 420

// original https://www.shadertoy.com/view/Wt3Xzr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float N21(vec2 p){
    float d = fract(cos(605.43*fract(sin(p.x*p.y*6725.)))*9284.);
    
    return d;
}
vec2 N22(vec2 p){
    float r = N21(p);
    return vec2(r,N21(vec2(r)));
}
float heart(vec2 p) {
    // Center it more, vertically:
    p.y += .6;
    // This offset reduces artifacts on the center vertical axis.
    const float offset = .2;
    // (x^2+(1.2*y-sqrt(abs(x)))^2−1)
    float k = 1.2 * p.y - sqrt(abs(p.x) + offset);
    return p.x * p.x + k * k - (7.*max(abs(sin(2.*time)),abs(cos(2.*time))));
}

float heart2(vec2 p) {
    // Center it more, vertically:
    float fft = 0.0; //texelFetch(iChannel0,ivec2(.7,0.), 0).x;
    float wave = 0.0; //texelFetch(iChannel0,ivec2(10.,0.),0).x;
    fft*=(wave);
    p.y += .3;
    // This offset reduces artifacts on the center vertical axis.
    const float offset = .3;
    // (x^2+(1.2*y-sqrt(abs(x)))^2−1)
    float k = 1.2 * p.y - sqrt(abs(p.x) + offset);
    return p.x * p.x + k * k - 1.*(1.5*fft);
}

vec3 background(vec2 uv){
    
    float wave = 0.0; //texelFetch(iChannel0,ivec2(10.,0.),0).x;
    wave*=abs(uv.y*.2);
    return vec3(wave)*vec3(2.,.8,.8)+vec3(.1,.1,.1); 
}
vec3 voro(vec2 uv){
float m = 0.;
    float t = time;
    float minD = 100.;
    float closestcell = 0.;
    
        uv*=5.;
        vec2 gv = fract(uv)-.5;
        vec2 id = floor(uv);
        
        for(float x = -1.; x <=1.; x++){
            for(float y=-1.; y<=1.; y++){
                vec2 offset = vec2(x,y);
                vec2 n = N22(vec2(id+offset));

                vec2 p = .5*sin(n*t)+offset; //-1 to 1 
                
                float d = pow(heart2(gv-p),3.)*.6;
                if(d<minD){
                minD = d;
                //closestcell = float(i);
                }
        
           }
        
    }
    vec3 voro = (vec3(.5,.0,.1)-minD)*pow(vec3(1.,.4,.4),vec3(.4)); 
    return voro;    
}
void main(void)
{
    // Normalized pixel coordinates -.5 to .5
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv-=.5;
    uv.x*=resolution.x/resolution.y;
    vec3 col = vec3(0.);
    
    //the inner voronoi pattern in the heart
    vec3 voro = voro(uv);
    col=voro;
    
    //create heart shape and background effect
    uv*=5.;
    float heart = heart(uv);
    
    //ad background
    vec3 back_ground = background(uv);
    if(heart>0.){
    col = back_ground;
    }
    
    //add border to heart uncomment 2nd color
    //to have a PPG like effect
    if(heart > 0. && heart < 1.){
    col = mix(back_ground,vec3(1.),heart*heart);
        
    
    }
    
    //assumes animation start from beginning
    //col = 1.-smoothstep(back_ground,vec3(1.),vec3(heart*heart));
    if((time > 66. && time < 97.) ||
       (time>129. && time < 160.) ){
        col *= 1.-smoothstep(back_ground,vec3(1.),vec3(heart*heart));
        col+=voro;
    }
     
    
    glFragColor = vec4(col,1.0);
}

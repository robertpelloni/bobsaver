#version 420

// original https://www.shadertoy.com/view/sdVXWz

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159

float hash21(vec2 p) {return fract(fract(dot(p,vec2(5.15123,2.1235)))*41.3151);}
float circle (vec2 p, vec2 c, float r, float w) {return 1.-smoothstep(0.,.01,abs(length(p-c)-r)- w);}
mat2 rot2(float a) {return mat2(cos(a), -sin(a), sin(a), cos(a));}

void main(void)
{
  
    vec2 uv = ( gl_FragCoord.xy - resolution.xy * .5 ) / resolution.y;

    uv *= 3.;
    uv += vec2(time * .1, -time*.15);
    
    float steps = 7.; // play with this value :)
    float backclfun = clamp(sin(uv.x*2.)*sin(uv.y*2.)*.5+.5,1./abs(steps)-.01,1.)-.001;
    float bclffl = floor((backclfun)*abs(steps));
    float bclffr = backclfun*steps-bclffl;
    
    vec3 col = mix(vec3(.55, .55, .96), vec3(.96, .55, .52), clamp(bclffl / steps,0.,1.)) ;
    
    vec2 grid = floor(uv);
    float id = hash21(grid);
    vec2 cent = uv-grid-.5;
    cent = rot2(PI/2. * floor(id * 7.)) * cent;

    vec3 cl = col;
    col = mix(col, (1.-col)*1.2, circle(cent, vec2( .5, .5), .65, .001));
    col = mix(col, (1.-col)*1.2, circle(cent, vec2( .5, .5), .35, .001));
    col = mix(col, (1.-col)*1.2, circle(cent, vec2(-.5,-.5), .65, .001));
    col = mix(col, (1.-col)*1.2, circle(cent, vec2(-.5,-.5), .35, .001));
    
    col = mix(col, (1.-cl)*1.2, circle(cent, vec2(-.5,.5), .5, .063));
    col = mix(col, (1.-cl)*1.2, circle(cent, vec2(.5,-.5), .5, .063));
    col = mix(col, vec3(.9), circle(cent, vec2(-.5,.5), .5, .05));
    col = mix(col, vec3(.9), circle(cent, vec2(.5,-.5), .5, .05));

    //col = mix(col, vec3(0.), float(texture(iChannel0, cent).xyz) * .2);

    col = mix(col, vec3(PI*.1), pow(1.-bclffr, PI));
    
    glFragColor = vec4(col,1.0);
}

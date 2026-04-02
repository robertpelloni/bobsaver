#version 420

// original https://www.shadertoy.com/view/fsGGDG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

mat2 rotate2d(float _angle){
    return mat2(cos(_angle),-sin(_angle),
                sin(_angle),cos(_angle));
}

void main(void)
{
    
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    vec3 col = vec3( 0.,0.,0.);
    
    float time = time;
    
    uv *= rotate2d( sin(uv.y * uv.x * 2.9) *sin(time/5.)/4. );
   
   
    uv *= abs(cos(uv/1.8) +0.2);
    
    vec2 pos = vec2(0.5 + cos(time)/1.3,0.5 + sin(time)/8.) - uv;
    float r = length(pos) * 80.;
    float a = atan(cos(pos.x),sin(pos.y+ time/2.));
    
    a = abs(a*30.);
    
    r/= 30. * abs(sin(time)/3. + 1.);
    float pattern = smoothstep(sin(pos.y*15. + time),sin(time/9.),cos(a/r + time * 20.)) * (pow(r,7.));
    
    col = vec3(pattern);
    
   
   glFragColor = vec4(col,1.0);
}

#version 420

// original https://www.shadertoy.com/view/XdGyWG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159265358979323846
vec3 hsb2rgb( in vec3 c ){
    vec3 rgb = clamp(abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),
                             6.0)-3.0)-1.0,
                     0.0,
                     1.0 );
    rgb = rgb*rgb*(3.0-2.0*rgb);
    return c.z * mix( vec3(1.0), rgb, c.y);
}

vec2 rotate2D(vec2 _st, float _angle){
    // _st -= 0.5;
    _st =  mat2(cos(_angle),-sin(_angle),
                sin(_angle),cos(_angle)) * _st;
    // _st += 0.5;
    return _st;
}

vec2 tile(vec2 _st, float _zoom){
    _st = _st*.5+.5;
    _st *= _zoom;
    return fract(_st);
}

float box(vec2 _st, vec2 _size, float _smoothEdges){
    _size = -_size*.5;
    vec2 aa = vec2(_smoothEdges*0.5);
    vec2 uv = smoothstep(_size,_size+aa,_st);
    uv *= smoothstep(_size,_size+aa,-_st);
    return uv.x*uv.y;
}

void main(void)
{
    vec2 st = (gl_FragCoord.xy*2.-resolution.xy)/resolution.x;
    vec3 c = hsb2rgb(vec3(.06, .86,1.));
    
    // Distance from 0 to 1
    float r = length(st)*1.;
    float s = pow(cos(r*4.-time*3.),20.)*.1;
    st *= 1.-s;
    st = tile(st,25.);
    st = st*2.-1.;
    float pct = (.5+sin(r*1.+time*0.)*.5);
    
    vec3 color = c;
    st = rotate2D(st,PI*0.25);
    
    // Draw a square
    color *= vec3(box(st,vec2(.6),0.1));
    st = rotate2D(st,PI*.75);
    float w = .2;
    color += (c-color)*vec3(box(st,vec2(w, 2.1),.1));
    st = rotate2D(st,PI*.5);
    color += (c-color)*vec3(box(st,vec2(w, 2.1),.1));
    color += s*color*15.;

    glFragColor = vec4(color,1.0);
}

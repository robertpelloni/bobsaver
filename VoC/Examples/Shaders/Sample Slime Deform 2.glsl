#version 420

// original https://www.shadertoy.com/view/4lXfRf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// um, some kind of mystical hole...?

float glint(vec2 p)
{
    vec2 uv = p;
    float speed = 0.68;
    float linewidth = 1.38;
    float grad = 3.0;
    vec2 linepos = uv;
    linepos.x = linepos.x - mod(time*speed,4.0)+2.0;
    float y = linepos.x*grad;
    float s = smoothstep( y-linewidth, y, linepos.y) - smoothstep( y, y+linewidth, linepos.y); 
    return s;
}

float _glint(vec2 gl_FragCoord )
{
    vec2 p = (-resolution.xy + 2.0*gl_FragCoord.xy) / resolution.y;
    float speed = time*0.2;
     float d = 1.0+p.x*0.25;
    vec2 cst = vec2( cos(d+speed), sin(d+speed) );
    float zoom = 1.0+(0.5*sin(time*0.675));
    mat2 rot = zoom * mat2(cst.x,-cst.y,cst.y,cst.x);
    float s = glint(p*rot*0.44);
    return s;
}

void main(void)
{
    vec2 p=gl_FragCoord.xy;
    vec4 k=vec4(0.0);

    const vec4 col1 = vec4(0.0,.1,.1,1.0);
    const vec4 col2 = vec4(0.5,0.9,0.3,1.0);
    vec2 uv = p.xy / resolution.xy;
    float gl = _glint(p)*0.5;

    
    
    float speed = time*0.2;
     float _fd = 1.0+uv.x*0.55;
    vec2 cst = vec2( cos(_fd+speed), sin(_fd+speed) );
    float zoom = 3.0+(0.5*sin(time*0.75));
    mat2 rot = zoom * mat2(cst.x,-cst.y,cst.y,cst.x);
    uv = rot*uv;
    
    float offset = mod( floor(uv.x+0.5), 2.0);
    offset*=2.0;
    
    
    
    float s = sin(time*0.1);
    float s2 = 0.5+sin(time*1.8);
    vec2 d = uv*(2.0+offset*2.0+s*.3);                        // mod 4.0 for irregularity...

    
    
    d.x += time*0.4-sin(d.x+d.y + time*0.3)*0.5;
    d.y += time*0.15+sin(d.x + time*0.3)*0.5;    //-(s*0.5);
    float v1=length(0.5-fract(d.xy))+0.55-(offset*0.1);                // 0.9 =more gooey bits, 1.2 = less gooey bits

    d = (uv);            // zoom
    d.x += 0.5;
    //d.x += offset*0.5;
    
    float v2=length(0.5-fract(d.xx))-0.175;        // border
    v1 *= 1.0-v2*v1;
    v1 = v1*v1*v1;
    v1 *= 2.9+s2*0.2;
    k = mix(col2,col1,v1)*(3.2+(s2*0.2));
    k *= 1.0-(v2);
    
    //k.r += offset;
    
    if (k.g<=0.4)
    {
        float m = 1.0-clamp(k.g,0.0,0.5);
        float f = mod( floor(12.0*uv.x) + floor(12.0*uv.y), 2.0);
        float col = 0.3 + 0.2*f*1.0;
        k.x = k.y = k.z = col*m;
        k.rb *= 1.2;
        k.r -= offset;
    }
    else
    {
        float f = mod( floor(12.0*uv.x) + floor(12.0*uv.y), 2.0);
        vec4 _col = 0.2*f*vec4(0.175);
        k+=_col;
    }
    // glint
    k *=vec4(1.0+gl);

    glFragColor=k;
}

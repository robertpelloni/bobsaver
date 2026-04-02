#version 420

// original https://www.shadertoy.com/view/mdfXRf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159265358979323846

float random (vec2 st) {
    return fract(sin(dot(st.xy,
                         vec2(12.9898,78.233)))*
        43758.5453123);
}

vec3 circle(vec2 uv, vec2 pos, float radius, vec3 colour)
{

    vec3 circ = vec3(step(length(uv - pos),radius));
    circ *= colour;
    
    return circ;
}

vec2 rotate2D (vec2 _st, float _angle) {
    _st -= 0.5;
    _st =  mat2(cos(_angle),-sin(_angle),
                sin(_angle),cos(_angle)) * _st;
    _st += 0.5;
    return _st;
}

vec2 rotateTilePattern(vec2 _st){

    //  Scale the coordinate system by 2x2
    _st *= 2.0;

    //  Give each cell an index number
    //  according to its position
    float index = 0.0;
    index += step(1., mod(_st.x,2.0));
    index += step(1., mod(_st.y,2.0))*2.0;

    //      |
    //  2   |   3
    //      |
    //--------------
    //      |
    //  0   |   1
    //      |

    // Make each cell between 0.0 - 1.0
    _st = fract(_st);

    // Rotate each cell according to the index
    if(index == 0.0){
        //  Rotate cell 1 by 90 degrees
        _st = rotate2D(_st,PI);
    }
    
    else if(index == 1.0){
        //  Rotate cell 1 by 90 degrees
        _st = rotate2D(_st,PI*-0.5);
    } 
    
    else if(index == 2.0){
        //  Rotate cell 2 by -90 degrees
        _st = rotate2D(_st,PI*0.5);
    } 
    
    else if(index == 3.0){
        //  Rotate cell 3 by 180 degrees
        //_st = rotate2D(_st,PI);
    }

    return _st;
}

float oscillator(vec2 iPos, float phase)
{
    return sin((time/2.0) + 3.0*random(iPos) + phase);
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv.x *= resolution.x/resolution.y;
    
    //uv = 2.0*(uv - vec2(0.5));
    uv += vec2(0.09*time,0.13*time);
    uv *= 8.0;
    vec2 iPos = floor(uv);
    uv = fract(uv);
    //int iPos = floor(uv);
    //float fPos = fract(uv);
    uv = rotateTilePattern(uv);

    uv = uv*1.0;
    
    
    
    vec3 col1 = vec3(1.0,0.5,0.0);
    //vec2 pos1 = vec2(0.25*((sin(time)) + 1.0));
    vec2 pos1 = vec2(abs(oscillator(vec2(0.0),0.0)));
    float scale1 = 0.5*abs(sin(time) + 0.1);
    scale1 = 0.5*abs(sin(time) + 0.1);
    //scale1 *= scale1;
    vec3 circ1 = circle(uv, pos1, scale1 ,col1);
    
    vec3 col2 = vec3(-abs(oscillator(iPos,PI/2.0) + 1.0)/2.0,-abs(oscillator(iPos,PI) + 1.0)/2.0,-abs(oscillator(iPos,0.0) + 1.0)/2.0);
    vec3 circ2 = circle(uv, vec2(0.5), 0.3,col2);
    
    vec3 col3 = col2.yxz;
    vec2 pos3 = vec2(0.5) + 0.3*vec2(sin(time),cos(time));
    vec3 circ3 = circle(uv, pos3, 0.1, col3);
    
    vec3 col4 = col2.zxy;
    vec2 pos4 = vec2(0.5) + 0.3*vec2(sin(time + PI),cos(time + PI));
    vec3 circ4 = circle(uv, pos4, 0.1, col4);
    
    // Output to screen
    glFragColor = vec4(circ1 - circ2 - circ3 - circ4,1.0);
    //glFragColor = vec4(circ1 * circ2 * circ3 * circ4,1.0);
}

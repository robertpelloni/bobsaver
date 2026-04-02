#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/flX3W4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float inBox ( vec2 uv, vec2 pmin, vec2 pmax ){
    return step( pmin.x, uv.x ) * ( 1.0 - step( pmax.x, uv.x ) ) *  step( pmin.y, uv.y ) * ( 1.0 - step( pmax.y, uv.y ) ) ;
}

float widthBox ( vec2 uv, float xc, float yc, float xw, float yw ){
    float minx = xc - xw / 2.0;
    float maxx = xc + xw / 2.0;
    float miny = yc - yw / 2.0;
    float maxy = yc + yw / 2.0;
    return inBox ( uv, vec2(minx,miny), vec2(maxx,maxy) );
}

vec3 boxes( vec2 uv)
{
   
    float columns[6] = float[6]( .142, .285, .428, .571, .714, .857 );
    float rows[4] = float[4]( .865, .625, .385, .145 );
    vec3 result = vec3(0.0);
    float mask = 0.0;
    
    for ( int i = 0; i < 24; i++ ){
        mask = widthBox( uv, columns[i%6], rows[int(i/6)], mix(0.1,.2,abs(sin(time+float(i)*uv.x*.1))),mix(0.1,0.5,abs(sin(time+float(i)+.25*uv.x*.1))) );
        result = mix ( result, vec3( (sin(time+float(i))+1.)/2.,(sin(time+float(i+3)+.855)+1.)/2.,(sin(time*3.+float(i+1)+.657)+1.)/2. ), mask );
    }
    
    return result;
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;   
    vec3 col = boxes( uv );
    glFragColor = vec4(col,1.0);
}


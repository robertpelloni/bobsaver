#version 420

// original https://www.shadertoy.com/view/tly3WR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//this function is from https://www.shadertoy.com/view/4djSRW
vec2 hash22(vec2 p)
{
    vec3 p3 = fract(vec3(p.xyx) * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yzx+33.33);
    return fract((p3.xx+p3.yz)*p3.zy+sin(time));

}

vec2 magnify(vec2 gl_FragCoord,float mag){
    return hash22(floor(gl_FragCoord.xy/pow(2.0,mag)));
}

vec2 pixel_above(vec2 gl_FragCoord,float mag){
    return magnify(gl_FragCoord+vec2(pow(2.0,mag),0),mag);
}

void main(void)
{
    vec2 color1 = vec2(0,0);
    float maximum = 5.0;
    for(float i = 1.0; i < 1.0+maximum; i++){
        color1 += pixel_above(gl_FragCoord.xy,i+1.0);
    }
    color1 /= maximum;
    glFragColor = vec4(0.0,color1,0.0);
}

#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;
uniform sampler2D backbuffer;

out vec4 glFragColor;
float round(float val,float n)
{
    return ((floor(val*n)/n)+(ceil(val*n)/n))/2.0;
}
float block(vec4 pos,vec2 size)
{
    return 1.0-(sign((abs(pos.x-pos.z)-(size.x/4.0))+((abs(pos.y-pos.w))-(size.y/2.0))));
}

void main(void) {

    vec2 position = (gl_FragCoord.xy/resolution.xy);
    vec4 tex = texture2D(backbuffer,position*0.95+0.025)-0.01;
    float color = block(vec4(vec2(position),0.5+cos(time*6.0)/10.0,0.5+sin(time*6.0)/5.0),vec2(0.05,0.05));
    glFragColor = vec4(vec3(color)+tex.rgb*vec3(0.99,0.98,0.7),1.0);

}

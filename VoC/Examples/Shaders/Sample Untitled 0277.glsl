#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float noise(float v, float amplitude, float frequency, float time) {
    float r = sin(v * frequency);
    float t = 0.01*(-time*130.0);
    r += sin(v*frequency*2.1 + t)*4.5;
    r += sin(v*frequency*1.72 + t*1.121)*4.0;
    r += sin(v*frequency*2.221 + t*0.437)*5.0;
    r += sin(v*frequency*3.1122+ t*4.269)*2.5;
    r *= amplitude*0.06;
    
    return r;
}
float circle(in vec2 _st, in float _radius){
        vec2 dist = _st-vec2(0.0);
    return 1.-smoothstep(_radius-(_radius*0.1), _radius+(_radius*0.1), dot(dist,dist)*4.0);
}

void main( void ) {
    vec2 position = ( gl_FragCoord.xy / resolution.xy );
    position.x -= 0.5;
    position.y -= 0.5;
    
    position.x *= resolution.x/resolution.y;
    
    vec3 color = vec3(0.0, 0.0, 0.0);
    
    color = vec3(circle(position, 0.5));
    
    color += noise(position.x, 1.0, 1.0, time);
    color *= noise(position.y, 10.0, 50.0, time);
    
    
    glFragColor = vec4(color, 1.0);

}

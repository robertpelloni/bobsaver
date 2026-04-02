#version 420

// gigatron france 

uniform vec2 resolution;
uniform float time;

out vec4 glFragColor;

vec3 hsv2rgb(vec3 c) {
    vec3 rgb = clamp(abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),6.0)-3.0)-1.0, 0.0, 1.0 );
    rgb = rgb*rgb*(3.0-2.0*rgb);
    return c.z*mix(vec3(1.0), rgb, c.y);
}

void main(void) {
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    
     uv   = mix(uv ,   tan(1.-abs(uv.xy)  * 64.0)/ 32.0 , 0.2);
        //uv   = mix(uv ,   sin(uv.yy  * 64.0)/ 16.0 , 0.2);
        uv.x = mix(uv.x , cos(uv.y  * 32.0)/ 4.0 , 0.1);
    uv.y = mix(uv.y , sin(uv.x  * 32.0)/ 2.0 , 0.2);
    

    glFragColor = vec4(hsv2rgb(vec3(uv.y+time*0.2, 1.0, 1.0)), 1.0);
}

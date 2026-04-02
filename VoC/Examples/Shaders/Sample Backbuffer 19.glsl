#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;
uniform sampler2D backbuffer;

out vec4 glFragColor;

void main( void ) {
    vec4 source = texture2D(backbuffer, gl_FragCoord.xy/resolution.xy);
    if ((source.a == 0.0) || (length((mouse - gl_FragCoord.xy/resolution.xy) * vec2(1.0, resolution.y/resolution.x)) < 0.025)
       || ((mouse.x > 0.95) && (mouse.y > 0.95))) {
        source = vec4(0.5,0.5,0.5,1.0);
    } else {
        float x = gl_FragCoord.x / resolution.x;
        float y = gl_FragCoord.y / resolution.y;
        vec2 offset = vec2(sin(x*4.43+time*0.1835) - sin(y*4.24+time*0.465) + sin((x+y)*3.43+time*0.1365),
                   sin(y*3.53+time*0.1533) - sin(x*5.58+time*0.268) + sin((x-y)*5.83+time*0.1674));
        offset *= 0.0003;
        offset.x += (mod(sin(time*0.254+sin(x)*2.4-cos(y)*94.5) * 3542.453, 1.0) - 0.5) / resolution.x;
        offset.y += (mod(sin(time*0.343+sin(x)*1.2-cos(y)*37.5) * 4357.753, 1.0) - 0.5) / resolution.y;
        source += texture2D(backbuffer, (gl_FragCoord.xy+vec2(1.0,0.0))/resolution.xy+offset);
        source += texture2D(backbuffer, (gl_FragCoord.xy+vec2(-1.0,0.0))/resolution.xy+offset);
        source += texture2D(backbuffer, (gl_FragCoord.xy+vec2(0.0,1.0))/resolution.xy+offset);
        source += texture2D(backbuffer, (gl_FragCoord.xy+vec2(0.0,-1.0))/resolution.xy+offset);
        source += texture2D(backbuffer, (gl_FragCoord.xy+vec2(1.0,1.0))/resolution.xy+offset);
        source += texture2D(backbuffer, (gl_FragCoord.xy+vec2(-1.0,1.0))/resolution.xy+offset);
        source += texture2D(backbuffer, (gl_FragCoord.xy+vec2(-1.0,-1.0))/resolution.xy+offset);
        source += texture2D(backbuffer, (gl_FragCoord.xy+vec2(1.0,-1.0))/resolution.xy+offset);
        source /= 9.0;
    }
    
    vec2 p = gl_FragCoord.xy;
    float noise = 0.14;
    glFragColor.r = source.r;    
    glFragColor.g = source.g; 
    glFragColor.b = source.b; 
    glFragColor.a = source.a;
    
    float rate = 1.5/255.0;
    float tolerance = 0.06;

    if (glFragColor.r > 0.5+tolerance) {glFragColor.r += rate;}
    else if (glFragColor.r < 0.5-tolerance) {glFragColor.r -= rate;}
    else {glFragColor.r += noise * sin((sin(time * 48.245) * sin((p.x+p.y) * 747.894) + sin(p.x * 558.325) * sin(p.y * 677.365)) * 348.493);}

    if (glFragColor.g > 0.5+tolerance) {glFragColor.g += rate;}
    else if (glFragColor.g < 0.5-tolerance) {glFragColor.g -= rate;}
    else {glFragColor.g += noise * sin((sin(time * 63.575) * sin((p.x+p.y) * 547.245) + sin(p.x * 235.753) * sin(p.y * 563.876)) * 348.493);}
    
    if (glFragColor.b > 0.5+tolerance) {glFragColor.b += rate;}
    else if (glFragColor.b < 0.5-tolerance) {glFragColor.b -= rate;}
    else {glFragColor.b += noise * sin((sin(time * 85.634) * sin((p.x+p.y) * 254.753) + sin(p.x * 753.452) * sin(p.y * 523.765)) * 348.493);}
    
    glFragColor.r = min(max(glFragColor.r, 0.0), 1.0);
    glFragColor.g = min(max(glFragColor.g, 0.0), 1.0);
    glFragColor.b = min(max(glFragColor.b, 0.0), 1.0);
}
